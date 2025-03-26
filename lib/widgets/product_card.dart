import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;
  final String id; // Add product ID for cart functionality

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with fixed dimensions
          SizedBox(
            height: 150, // Fixed height for all images
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Display a square placeholder when image fails to load
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Product Name with fixed height and better overflow protection
          SizedBox(
            height:
                42, // Fixed height for product name (2 lines * ~21px per line)
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Slightly smaller font size
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Product Price with overflow protection
          SizedBox(
            height: 20, // Fixed height for price
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
              child: Text(
                price,
                style: const TextStyle(color: Colors.green),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Add to Cart Button
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SizedBox(
              width: double.infinity,
              height: 36, // Fixed height for the button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9C88),
                  foregroundColor: Colors.white,
                  // Remove extra padding to avoid overflow
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                onPressed: () {
                  // Add the item to cart
                  final cart = Provider.of<Cart>(context, listen: false);
                  cart.addItem(
                    id,
                    name,
                    double.parse(price.replaceAll('\$', '')),
                    imageUrl,
                  );

                  // Show a snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name added to cart!'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          cart.removeSingleItem(id);
                        },
                      ),
                    ),
                  );
                },
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Add to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
