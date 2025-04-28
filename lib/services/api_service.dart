import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopease/config/network_config.dart';
import 'package:shopease/models/produit_vendeur.dart';

class ApiService {
  // URL courante utilisée pour les requêtes API
  String _currentBaseUrl = NetworkConfig.baseApiUrl;
  int _failureCount = 0;

  // Storage key for the auth token
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Create a custom HTTP client that bypasses certificate verification if configured
  http.Client _createCustomClient() {
    // Create a custom HTTP client with extended timeout for mobile devices
    HttpClient httpClient = HttpClient()
      ..connectionTimeout =
          Duration(seconds: NetworkConfig.connectionTimeout * 2)
      ..idleTimeout = Duration(seconds: 30); // Add idle timeout

    // Only bypass security in development with explicit permission
    if (NetworkConfig.allowInsecureConnections) {
      httpClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
    }

    return IOClient(httpClient);
  }

  // Try request with fallback URLs if the main one fails
  Future<http.Response> _tryRequestWithFallback({
    required Future<http.Response> Function(String baseUrl) requestFn,
  }) async {
    try {
      // Try with current URL first
      print('Attempting connection to: $_currentBaseUrl');
      return await requestFn(_currentBaseUrl);
    } on HandshakeException catch (e) {
      print('SSL/TLS Handshake failed: ${e.toString()}');

      // Check if we're using HTTPS and consider switching to HTTP for test/dev environments
      if (_currentBaseUrl.startsWith('https://')) {
        final httpUrl = _currentBaseUrl.replaceFirst('https://', 'http://');
        print('Trying with HTTP instead: $httpUrl');

        try {
          return await requestFn(httpUrl);
        } catch (innerError) {
          print('HTTP fallback also failed: $innerError');
          // Continue to fallback URLs or throw
        }
      }

      // If HTTP fallback failed or wasn't attempted, try other fallback URLs
      _failureCount++;
      if (_failureCount <= NetworkConfig.fallbackUrls.length) {
        _currentBaseUrl = NetworkConfig.fallbackUrls[_failureCount - 1];
        print('Trying fallback URL: $_currentBaseUrl');
        await Future.delayed(Duration(milliseconds: 500));
        return await requestFn(_currentBaseUrl);
      } else {
        _failureCount = 0;
        _currentBaseUrl = NetworkConfig.baseApiUrl;
        throw Exception(
            'Erreur de connexion sécurisée. Le serveur ne supporte pas HTTPS correctement ou ' +
                'le certificat n\'est pas valide. Essayez avec HTTP si c\'est un environnement de test.');
      }
    } on SocketException catch (e) {
      // Connection error, try fallback URLs if available
      _failureCount++;
      print('Connection failed to $_currentBaseUrl: ${e.message}');

      if (_failureCount <= NetworkConfig.fallbackUrls.length) {
        // Try next URL in the fallback list
        _currentBaseUrl = NetworkConfig.fallbackUrls[_failureCount - 1];
        print('Trying fallback URL: $_currentBaseUrl');

        // Add small delay before retry to avoid overwhelming the network
        await Future.delayed(Duration(milliseconds: 500));
        return await requestFn(_currentBaseUrl);
      } else {
        // All URLs failed
        _failureCount = 0; // Reset for next attempt
        _currentBaseUrl = NetworkConfig.baseApiUrl; // Reset to default URL
        throw SocketException(
          'Impossible de se connecter au serveur après plusieurs tentatives. '
          'Vérifiez que le serveur est en cours d\'exécution et que le port est correct.',
          address: e.address,
          port: e.port,
        );
      }
    } catch (e) {
      // Other errors, just rethrow
      print('Unexpected error during request: ${e.toString()}');
      rethrow;
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> registerUser(
      String name, String email, String password, String userType) async {
    final client = _createCustomClient();

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': name,
            'email': email,
            'password': password,
            'user_type': userType, // 'customer' or 'vendor'
          }),
        ),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save the token and user data
        await _saveAuthData(responseData);
        return responseData;
      } else {
        // Handle error response from the API
        final errorMessage =
            responseData['message'] ?? 'Échec de l\'inscription';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network or other errors with more specific message
      if (e is HandshakeException) {
        throw Exception(
            'Erreur de connexion sécurisée. Vérifiez votre configuration SSL ou utilisez HTTP.');
      } else if (e is SocketException) {
        throw Exception(
            'Impossible de se connecter au serveur. Vérifiez votre connexion réseau et que le serveur est bien lancé.');
      } else {
        throw Exception('Erreur de connexion: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Login user with the same error handling as register
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final client = _createCustomClient();

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
          }),
        ),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save the token and user data
        await _saveAuthData(responseData);
        return responseData;
      } else {
        // Handle error response from the API
        final errorMessage = responseData['message'] ?? 'Échec de la connexion';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network or other errors with more specific message
      if (e is HandshakeException) {
        throw Exception(
            'Erreur de connexion sécurisée. Vérifiez votre configuration SSL ou utilisez HTTP.');
      } else if (e is SocketException) {
        throw Exception(
            'Impossible de se connecter au serveur. Vérifiez votre connexion réseau et que le serveur est bien lancé.');
      } else {
        throw Exception('Erreur de connexion: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Save authentication data (token and user info)
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.containsKey('token')) {
      await prefs.setString(_tokenKey, data['token']);
    }

    if (data.containsKey('user')) {
      await prefs.setString(_userKey, json.encode(data['user']));
    }
  }

  // Get the stored auth token
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get the stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      return json.decode(userData) as Map<String, dynamic>;
    }
    return null;
  }

  // Logout user (clear stored data)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // ----- Product Management Methods -----

  // Get all products for the logged-in vendor
  Future<List<ProduitVendeur>> getVendorProducts() async {
    final client = _createCustomClient();
    final token = await getAuthToken();

    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.get(
          Uri.parse('$baseUrl/products/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final userData = await getUserData();
        final userType = userData?['user_type'];

        print('Received ${responseData.length} products from server');
        print('User type: $userType');

        // For customers or admin, show all products
        // For vendors, only show their own products
        List<dynamic> filteredProducts;
        if (userType == 'vendor') {
          final vendorId = userData?['id'];
          filteredProducts = responseData
              .where((product) => product['vendor_id'] == vendorId)
              .toList();
          print(
              'Filtered to ${filteredProducts.length} products for vendor $vendorId');
        } else {
          // For customers and admins, show all products
          filteredProducts = responseData;
        }

        return filteredProducts
            .map((product) => ProduitVendeur.fromJson(product))
            .toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ??
            'Erreur lors de la récupération des produits');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Erreur de connexion au serveur. Vérifiez votre connexion réseau.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des produits: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Get specific product details by ID
  Future<ProduitVendeur> getProductById(String productId) async {
    final client = _createCustomClient();
    final token = await getAuthToken();

    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.get(
          Uri.parse('$baseUrl/products/$productId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        return ProduitVendeur.fromJson(productData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Produit non trouvé');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Erreur de connexion au serveur. Vérifiez votre connexion réseau.');
      } else {
        throw Exception(
            'Erreur lors de la récupération du produit: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Add a new product with image upload support - updated to match FastAPI backend
  Future<ProduitVendeur> addProduct(ProduitVendeur produit,
      {XFile? imageFile}) async {
    final client = _createCustomClient();
    final token = await getAuthToken();

    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      // Create multipart request to match FastAPI endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_currentBaseUrl/products/'),
      );

      // Add authorization headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add product data as fields - match field names with FastAPI endpoint
      request.fields['name'] = produit.nom;
      request.fields['description'] = produit.description ?? '';
      request.fields['price'] = produit.prix.toString();
      request.fields['stock'] = produit.quantite.toString();
      if (produit.barcode != null && produit.barcode!.isNotEmpty) {
        request.fields['barcode'] = produit.barcode!;
      }

      // Add image if provided
      if (imageFile != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await imageFile.readAsBytes();
          final filename = imageFile.name;

          // Create a multipart file with the correct field name 'image' to match FastAPI
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
            contentType: MediaType('image', _getImageFileType(filename)),
          ));
        } else {
          // For mobile platforms
          final file = File(imageFile.path);
          final filename = file.path.split('/').last;

          // Create a multipart file with the correct field name 'image' to match FastAPI
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: MediaType('image', _getImageFileType(filename)),
          ));
        }
      }

      // Send request
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      // Debug information for troubleshooting
      print("Server response status: ${response.statusCode}");
      print("Server response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse the response carefully
        try {
          final productData = json.decode(response.body);
          return ProduitVendeur.fromJson(productData);
        } catch (e) {
          print("JSON parsing error: $e");
          throw Exception(
              'Erreur lors du décodage de la réponse du serveur: $e\nRéponse reçue: ${response.body}');
        }
      } else {
        // Handle error responses
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['detail'] ?? 'Erreur lors de l\'ajout du produit';
        } catch (e) {
          // If JSON parsing fails, use raw response body
          errorMessage =
              'Erreur serveur: ${response.statusCode}\nRéponse: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Erreur de connexion au serveur. Vérifiez votre connexion réseau.');
      } else if (e is FormatException) {
        throw Exception(
            'Erreur de format dans la réponse du serveur. Détails: ${e.toString()}');
      } else {
        throw Exception('Erreur lors de l\'ajout du produit: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Update an existing product with image upload support - Updated to match FastAPI backend
  Future<ProduitVendeur> updateProduct(String productId, ProduitVendeur produit,
      {XFile? imageFile, bool deleteImage = false}) async {
    final client = _createCustomClient();
    final token = await getAuthToken();

    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      // Create multipart request to match FastAPI endpoint
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_currentBaseUrl/products/$productId'),
      );

      // Add authorization headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add product data as fields - match field names with FastAPI endpoint
      request.fields['name'] = produit.nom;
      request.fields['description'] = produit.description ?? '';
      request.fields['price'] = produit.prix.toString();
      request.fields['stock'] = produit.quantite.toString();
      request.fields['delete_image'] = deleteImage.toString();
      if (produit.barcode != null && produit.barcode!.isNotEmpty) {
        request.fields['barcode'] = produit.barcode!;
      }

      // Add new image if provided
      if (imageFile != null) {
        if (kIsWeb) {
          // For web platform
          final bytes = await imageFile.readAsBytes();
          final filename = imageFile.name;

          // Create a multipart file with the correct field name 'image' to match FastAPI
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename,
            contentType: MediaType('image', _getImageFileType(filename)),
          ));
        } else {
          // For mobile platforms
          final file = File(imageFile.path);
          final filename = file.path.split('/').last;

          // Create a multipart file with the correct field name 'image' to match FastAPI
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: MediaType('image', _getImageFileType(filename)),
          ));
        }
      }

      // Send request
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print("Update product response status: ${response.statusCode}");
      print("Update product response body: ${response.body}");

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        return ProduitVendeur.fromJson(productData);
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['detail'] ??
              'Erreur lors de la modification du produit';
        } catch (e) {
          errorMessage =
              'Erreur serveur: ${response.statusCode}\nRéponse: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Erreur de connexion au serveur. Vérifiez votre connexion réseau.');
      } else {
        throw Exception(
            'Erreur lors de la modification du produit: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    final client = _createCustomClient();
    final token = await getAuthToken();

    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.delete(
          Uri.parse('$baseUrl/products/$productId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['detail'] ?? 'Erreur lors de la suppression du produit';
        } catch (e) {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Erreur de connexion au serveur. Vérifiez votre connexion réseau.');
      } else {
        throw Exception(
            'Erreur lors de la suppression du produit: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  // Helper method to get file extension/mimetype
  String _getImageFileType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // Default fallback
    }
  }
}
