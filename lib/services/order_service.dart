import 'dart:convert';
import 'package:shopease/config/network_config.dart';
import 'package:shopease/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:io';

class OrderItem {
  final String productId;
  final int quantity;
  final double price;
  final String name;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'price': price,
        'name': name,
      };
}

class OrderService {
  final ApiService _apiService = ApiService();
  String _currentBaseUrl = NetworkConfig.baseApiUrl;
  int _failureCount = 0;

  // Create a custom HTTP client that bypasses certificate verification if configured
  http.Client _createCustomClient() {
    if (NetworkConfig.allowInsecureConnections) {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true)
        ..connectionTimeout =
            Duration(seconds: NetworkConfig.connectionTimeout);
      return IOClient(httpClient);
    } else {
      return http.Client();
    }
  }

  // Try request with fallback URLs if the main one fails
  Future<http.Response> _tryRequestWithFallback({
    required Future<http.Response> Function(String baseUrl) requestFn,
  }) async {
    try {
      return await requestFn(_currentBaseUrl);
    } on SocketException catch (e) {
      _failureCount++;

      if (_failureCount <= NetworkConfig.fallbackUrls.length) {
        _currentBaseUrl = NetworkConfig.fallbackUrls[_failureCount - 1];
        print('Connection failed, trying fallback URL: $_currentBaseUrl');
        return await requestFn(_currentBaseUrl);
      } else {
        _failureCount = 0;
        _currentBaseUrl = NetworkConfig.baseApiUrl;
        throw SocketException(
          'Unable to connect to the server after multiple attempts.',
          address: e.address,
          port: e.port,
        );
      }
    }
  }

  Future<Map<String, dynamic>> createOrder(
    List<OrderItem> items,
    double totalPrice,
    String deliveryAddress,
  ) async {
    final client = _createCustomClient();
    final token = await _apiService.getAuthToken();
    final userData = await _apiService.getUserData();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Make sure we have user data
    if (userData == null || userData['id'] == null) {
      throw Exception('User information is missing');
    }

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.post(
          Uri.parse('$baseUrl/orders/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'products': items.map((item) => item.toJson()).toList(),
            'total_price': totalPrice,
            'status': 'pending',
            'delivery_address': deliveryAddress,
            'user_id': userData[
                'id'], // Include user_id from the authenticated user data
          }),
        ),
      );

      print('Order creation response status: ${response.statusCode}');
      print('Order creation response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to create order');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Connection error. Please check your network connection.');
      } else {
        throw Exception('Error creating order: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }

  Future<List<Map<String, dynamic>>> getUserOrders() async {
    final client = _createCustomClient();
    final token = await _apiService.getAuthToken();

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => client.get(
          Uri.parse('$baseUrl/orders/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
            'Connection error. Please check your network connection.');
      } else {
        throw Exception('Error fetching orders: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }
}
