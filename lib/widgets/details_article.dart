import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../screens/panier_page.dart';

class DetailsArticle extends StatefulWidget {
  final String id; // Add this
  final String category;
  final String articleName;
  final double price;
  final String description;
  final String imageUrl;
  final VoidCallback? onAddToCart; // Make this optional

  const DetailsArticle({
    Key? key,
    required this.id, // Add this
    required this.category,
    required this.articleName,
    required this.price,
    required this.description,
    required this.imageUrl,
    this.onAddToCart, // Make this optional
  }) : super(key: key);

  @override
  State<DetailsArticle> createState() => _DetailsArticleState();
}

class _DetailsArticleState extends State<DetailsArticle> {
  int quantity = 1; // Add quantity state

  void _handleAddToCart(BuildContext context) {
    // Get the cart from provider
    final cart = Provider.of<Cart>(context, listen: false);

    // Add to cart with the current quantity
    cart.addItems(
      widget.id,
      widget.articleName,
      widget.price,
      widget.imageUrl,
      quantity,
    );

    // Show feedback to user
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.articleName} ajouté au panier!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VOIR PANIER',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PanierPage()),
            );
          },
        ),
      ),
    );

    // Call the provided callback if available
    if (widget.onAddToCart != null) {
      widget.onAddToCart!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF5D9C88).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                widget.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Catégorie
          Text(
            widget.category,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Nom de l'article
          Text(
            widget.articleName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // Prix
          Text(
            '\$${widget.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Texte "Description" avec fontSize 18
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // Description du produit
          Text(
            widget.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // Add quantity selector
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Quantité:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                          });
                        }
                      },
                    ),
                    Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Button with updated onPressed handler
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _handleAddToCart(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text(
                'Ajouter au panier',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D9C88),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
