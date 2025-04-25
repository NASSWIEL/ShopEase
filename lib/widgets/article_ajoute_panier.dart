import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/cart.dart';
import 'package:untitled/models/cart_item.dart';

class ArticleAjoutePanier extends StatelessWidget {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final int quantity;

  const ArticleAjoutePanier({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
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
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: FittedBox(
                  child: Text('\$$price'),
                ),
              ),
            ),
            title: Text(productName),
            subtitle: Text('Total: \$${(price * quantity).toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    // TODO: Implement "Buy Now" logic here.
                    print('Buy now clicked');
                    Provider.of<Cart>(context, listen: false)
                        .decrementQuantity(productId);
                  },
                ),
                Text('$quantity'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Provider.of<Cart>(context, listen: false)
                        .incrementQuantity(productId);
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
  factory ArticleAjoutePanier.fromCartItem(CartItem item) {
    return ArticleAjoutePanier(
      productId: item.id,
      productName: item.title, // Use the title getter we added
      price: item.price,
      imageUrl: item.imageUrl,
      quantity: item.quantity,
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
    );
  }

  // Helper method to get non-null image URL
  String get imageUrlOrDefault => imageUrl ?? 'https://via.placeholder.com/80';
}
