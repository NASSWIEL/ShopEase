import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Product Name
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Product Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(price, style: const TextStyle(color: Colors.green)),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
