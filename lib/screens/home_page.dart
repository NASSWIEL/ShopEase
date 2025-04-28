import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shopease/screens/login_page.dart';
import 'package:shopease/services/api_service.dart';
import 'package:shopease/models/produit_vendeur.dart';
import 'package:shopease/models/product_adapter.dart';
import 'package:shopease/utils/permissions_handler.dart';

import 'package:shopease/widgets/product_card.dart';
import 'package:shopease/screens/panier_page.dart';
import 'package:shopease/screens/details_article_page.dart';
import 'package:shopease/widgets/details_article.dart';
import 'package:shopease/widgets/profile_logout_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool _isListening = false;
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  // Speech to text
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  // List to store products from API
  List<ProduitVendeur> _products = [];

  List<ProduitVendeur> get filteredProducts {
    // First filter out products with zero stock
    final inStockProducts =
        _products.where((product) => product.quantite > 0).toList();

    // Then apply search filter if needed
    if (_searchQuery.isEmpty) {
      return inStockProducts;
    }
    return inStockProducts
        .where(
          (product) => product.nom.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchProducts();
    _initSpeech();
  }

  // This initializes SpeechToText
  Future<void> _initSpeech() async {
    try {
      print("Starting speech recognition initialization...");
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech recognition status change: $status');
          // Update UI state when status changes (like when recognition starts/stops)
          if (status == 'listening') {
            setState(() {
              _isListening = true;
            });
          } else if (status == 'notListening' || status == 'done') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (errorNotification) {
          print('Speech recognition error: $errorNotification');
          // Show error message to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recognition error: $errorNotification')),
          );
          setState(() {
            _isListening = false;
          });
        },
        debugLogging: true,
      );
      print("Speech initialized successfully: $_speechEnabled");

      if (_speechEnabled) {
        // Check what languages are available
        try {
          final languages = await _speechToText.locales();
          print("Available languages: ${languages.length}");
          for (var lang in languages.take(5)) {
            // Print just the first 5 to avoid flooding logs
            print("Language: ${lang.localeId} - ${lang.name}");
          }
        } catch (e) {
          print("Error getting languages: $e");
        }
      }

      setState(() {});
    } catch (e) {
      print("Speech initialization error: $e");
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _speechToText.cancel();
    super.dispose();
  }

  // Fetch products from the API
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("Fetching products from API...");
      final products = await _apiService.getVendorProducts();
      print("Fetched ${products.length} products from API");

      if (products.isEmpty) {
        print("WARNING: No products found in the API response!");
      } else {
        // Print first product details for debugging
        print("First product: ${products.first.nom}, ID: ${products.first.id}");
      }

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print("ERROR fetching products: ${e.toString()}");
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des produits: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // This starts listening for speech
  Future<void> _startListening() async {
    try {
      // Request microphone permission
      final bool hasPermission =
          await PermissionsHandler.requestMicrophonePermission(context);
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }

      // Check if speech is initialized, if not try to initialize again
      if (!_speechEnabled) {
        await _initSpeech();
        if (!_speechEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
          return;
        }
      }

      // Get available languages
      try {
        var locales = await _speechToText.locales();
        print(
            "Available locales: ${locales.map((e) => '${e.localeId}').join(', ')}");
      } catch (e) {
        print("Error getting locales: $e");
      }

      // Start listening to user input - remove the localeId to use device default language
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      setState(() {
        _isListening = true;
      });
    } catch (e) {
      print("Error starting speech recognition: $e");
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start speech recognition: $e')),
      );
    }
  }

  // This stops listening for speech
  void _stopListening() {
    try {
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print("Error stopping speech recognition: $e");
    }
  }

  // This is called each time speech is detected
  void _onSpeechResult(SpeechRecognitionResult result) {
    print("Speech result received: ${result.recognizedWords}");

    if (result.finalResult) {
      print("FINAL speech result: ${result.recognizedWords}");
    }

    // Update UI on main thread to ensure it gets applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _lastWords = result.recognizedWords;
          _searchController.text = result.recognizedWords;
          _searchQuery = result.recognizedWords;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: ProfileLogoutWidget(),
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 55,
          colorFilter: null,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF5D9C88)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanierPage()),
              );
            },
          ),
        ],
      ),
      // No more drawer since we're using ProfileLogoutWidget

      // Corps principal
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[200],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF5D9C88)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher des produits...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color:
                            _isListening ? Colors.red : const Color(0xFF5D9C88),
                      ),
                      onPressed: () {
                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Grille de produits
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : GridView.builder(
                          itemCount: filteredProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            childAspectRatio: 0.7,
                          ),
                          itemBuilder: (context, index) {
                            final produitVendeur = filteredProducts[index];
                            // Convert ProduitVendeur to Product
                            final product = ProductAdapter.fromProduitVendeur(
                                produitVendeur);

                            return GestureDetector(
                              onTap: () {
                                // On navigue vers la page de détails en passant le product
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      // Extraction des informations du produit
                                      final imageUrl =
                                          produitVendeur.imageUrl ??
                                              'https://via.placeholder.com/400';

                                      final articleName = produitVendeur.nom ??
                                          'Unknown Product';
                                      final price = produitVendeur.prix ?? 0.0;
                                      final description =
                                          produitVendeur.description ??
                                              'No description provided.';

                                      return DetailsArticlePage(
                                        imageUrl: imageUrl,
                                        detailsWidget: DetailsArticle(
                                          id: produitVendeur.id.toString(),
                                          articleName: articleName,
                                          price: price,
                                          description: description,
                                          imageUrl: imageUrl,
                                          onAddToCart: () {
                                            print('Article ajouté au panier');
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: ProductCard(
                                product: product,
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
