import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/screens/login_page.dart';
import 'package:untitled/services/api_service.dart';
import 'package:untitled/models/produit_vendeur.dart';
import 'package:untitled/models/product_adapter.dart'; // Import our new adapter

import 'package:untitled/widgets/product_card.dart';
import 'package:untitled/screens/panier_page.dart';
import 'package:untitled/screens/details_article_page.dart';
import 'package:untitled/widgets/details_article.dart';
import 'package:untitled/widgets/profile_logout_widget.dart';

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

  // List to store products from API
  List<ProduitVendeur> _products = [];

  List<ProduitVendeur> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
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

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });

    try {
      // Simulation de l'appel à une API de reconnaissance vocale
      await Future.delayed(const Duration(seconds: 2));
      final String transcribedText =
          "example product"; // Exemple de transcription

      setState(() {
        _searchController.text = transcribedText;
        _searchQuery = transcribedText;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Speech recognition failed: $e')));
    } finally {
      setState(() {
        _isListening = false;
      });
    }
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
                      onPressed: _startListening,
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
