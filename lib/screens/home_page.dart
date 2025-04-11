import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untitled/widgets/product_card.dart';
import 'package:untitled/screens/panier_page.dart';
import 'package:untitled/screens/details_article_page.dart';
import 'package:untitled/widgets/details_article.dart';
import 'package:untitled/screens/connexion_page.dart'; // Import for logout redirection

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

  // Exemple de liste de produits.
  // Tu peux ajouter un champ "category" ou "description" si tu les as.
  final List<Map<String, String>> allProducts = [
    {
      'name': 'Nike Futura Core Bucket Hat - Black',
      'price': '\$29.99',
      'imageUrl': 'https://picsum.photos/400?1',
      'description':
          'Great for casual mode during sunny weather with this Nike Futura bucket hat.',
      'category': 'Hat',
    },
    {
      'name': 'Product 2',
      'price': '\$30.00',
      'imageUrl': 'https://picsum.photos/400?2',
      'description': 'Short description for product 2.',
      'category': 'Shirt',
    },
    {
      'name': 'Product 3',
      'price': '\$30.00',
      'imageUrl': 'https://picsum.photos/400?2',
      'description': 'Short description for product 2.',
      'category': 'Shirt',
    },
    {
      'name': 'Product 4',
      'price': '\$30.00',
      'imageUrl': 'https://picsum.photos/400?2',
      'description': 'Short description for product 2.',
      'category': 'Shirt',
    },
    {
      'name': 'Product 5',
      'price': '\$30.00',
      'imageUrl': 'https://picsum.photos/400?2',
      'description': 'Short description for product 2.',
      'category': 'Shirt',
    },
    {
      'name': 'Product 6',
      'price': '\$30.00',
      'imageUrl': 'https://picsum.photos/400?2',
      'description': 'Short description for product 2.',
      'category': 'Shirt',
    },
    // ... Ajoute d’autres produits
  ];

  List<Map<String, String>> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return allProducts;
    }
    return allProducts
        .where(
          (product) => product['name']!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5D9C88),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            );
          },
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
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF5D9C88)),
              child: Text(
                'Menu ShopEase',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            // Logout option
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF5D9C88)),
              title: const Text('Déconnexion'),
              onTap: () async {
                // Clear user session
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('currentUser');
                await prefs.remove('currentUserType');

                if (context.mounted) {
                  // Close drawer
                  Navigator.pop(context);
                  // Navigate to login page and remove all previous routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ConnexionPage()),
                    (route) => false, // Remove all previous routes
                  );
                }
              },
            ),
            // Additional drawer items can be added here
          ],
        ),
      ),

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
              child: GridView.builder(
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return GestureDetector(
                    onTap: () {
                      // On navigue vers la page de détails en passant le product
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            // Extraction des informations du produit
                            final imageUrl = product['imageUrl'] ??
                                'https://via.placeholder.com/400';
                            final category =
                                product['category'] ?? 'Unknown Category';
                            final articleName =
                                product['name'] ?? 'Unknown Product';
                            final price = double.tryParse(
                                  product['price']?.replaceAll(
                                        RegExp(r'[^0-9.]'),
                                        '',
                                      ) ??
                                      '0',
                                ) ??
                                0.0;
                            final description = product['description'] ??
                                'No description provided.';

                            return DetailsArticlePage(
                              imageUrl: imageUrl,
                              detailsWidget: DetailsArticle(
                                id: index.toString(),
                                category: category,
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
                      id: index.toString(),
                      name: product["name"] ?? 'Unknown',
                      price: product["price"] ?? 'N/A',
                      imageUrl: product["imageUrl"] ?? '',
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
