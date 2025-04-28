import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopease/models/product.dart';
import '../models/cart.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF5D9C88),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero animation for smooth transition from list to details
              Hero(
                tag: 'product-${product.id}',
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  height: 300,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          product.price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D9C88),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Product description
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description ?? 'No description available.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Product specifications or additional info
                    if (product.specs != null && product.specs!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Specifications:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...product.specs!.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ${entry.key}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(child: Text(entry.value)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D9C88),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            onPressed: () {
              final cart = Provider.of<Cart>(context, listen: false);
              // Use the updated addItems method with proper parameters
              final price = double.tryParse(
                      product.price.replaceAll('\$', '').replaceAll('€', '')) ??
                  0.0;

              cart.addItems(
                product.id,
                product.name,
                price,
                product.imageUrl,
              );

              // Show feedback
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart!'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      cart.removeSingleItem(product.id);
                    },
                  ),
                ),
              );
            },
            child: const Text(
              'Add to Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
