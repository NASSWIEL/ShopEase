import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:untitled/widgets/product_card.dart';

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

  final List<Map<String, String>> allProducts = [
    {
      'name': 'Product 1',
      'price': '\$25.00',
      'imageUrl': 'https://picsum.photos/400',
    },
    {
      'name': 'Product 2',
      'price': '\$30.00',
      'imageUrl': 'https://picsum.photos/400',
    },
    {
      'name': 'Product 3',
      'price': '\$15.00',
      'imageUrl': 'https://picsum.photos/400',
    },
    {
      'name': 'Product 4',
      'price': '\$45.00',
      'imageUrl': 'https://picsum.photos/400',
    },
    {
      'name': 'Product 5',
      'price': '\$10.00',
      'imageUrl': 'https://picsum.photos/400',
    },
    {
      'name': 'Product 6',
      'price': '\$60.00',
      'imageUrl': 'https://picsum.photos/400',
    },
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
    // Toggle listening state for UI feedback
    setState(() {
      _isListening = true;
    });

    try {
      // This is a placeholder for the actual API call
      // In a real implementation, you would:
      // 1. Record audio
      // 2. Send it to your speech recognition API
      // 3. Receive the transcribed text

      // Simulating API delay
      await Future.delayed(const Duration(seconds: 2));

      // Example of what would happen after successful transcription
      final String transcribedText =
          "example product"; // This would come from your API

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
          height: 55, // Increased from 45
          colorFilter: null, // Remove color filter to use SVG's original colors
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF5D9C88)),
            onPressed: () {
              // TODO: Implement cart
            },
          ),
        ],
      ),
      drawer: Drawer(
        // TODO: Implement drawer content
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF5D9C88)),
              child: Text(
                'ShopEase Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                          hintText: 'Search products...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Color(0xFF5D9C88),
                      ),
                      onPressed: _startListening,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  return ProductCard(
                    name: product["name"] ?? 'Unknown',
                    price: product["price"] ?? 'N/A',
                    imageUrl: product["imageUrl"] ?? '',
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
