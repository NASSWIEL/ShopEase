import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopease/models/cart.dart';
import 'package:shopease/models/cart_item.dart';

class ArticleAjoutePanier extends StatelessWidget {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final int quantity;
  final int? stockLimit;

  const ArticleAjoutePanier({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.stockLimit,
  });

  @override
  Widget build(BuildContext context) {
    // Update the cart provider with the stock limit information if available
    if (stockLimit != null) {
      final cart = Provider.of<Cart>(context, listen: false);
      cart.setStockLimit(productId, stockLimit!);
    }

    return Dismissible(
      key: ValueKey(productId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 40,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<Cart>(context, listen: false).removeItem(productId);
      },
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Êtes-vous sûr?'),
            content: const Text(
              'Voulez-vous supprimer cet article du panier?',
            ),
            actions: [
              TextButton(
                child: const Text('Non'),
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                },
              ),
              TextButton(
                child: const Text('Oui'),
                onPressed: () {
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(),
              ),
            ),
            title: Text(productName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prix: \$${price.toStringAsFixed(2)}'),
                Text('Total: \$${(price * quantity).toStringAsFixed(2)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    Provider.of<Cart>(context, listen: false)
                        .decrementQuantity(productId);
                  },
                ),
                Text('$quantity'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final cart = Provider.of<Cart>(context, listen: false);
                    final success = cart.incrementQuantity(productId);

                    // Show message if couldn't increment due to stock limit
                    if (!success && cart.getStockLimit(productId) != null) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Impossible d\'ajouter plus de cet article. Stock maximum: ${cart.getStockLimit(productId)}',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Factory constructor to create from a CartItem
  factory ArticleAjoutePanier.fromCartItem(CartItem item, {int? stockLimit}) {
    return ArticleAjoutePanier(
      productId: item.id,
      productName: item.title, // Use the title getter we added
      price: item.price,
      imageUrl: item.imageUrl,
      quantity: item.quantity,
      stockLimit: stockLimit,
    );
  }

  // Display the image
  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrlOrDefault,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error for URL: $imageUrl');
        return Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }

  // Helper method to get non-null image URL
  String get imageUrlOrDefault => imageUrl ?? 'https://via.placeholder.com/80';
}
