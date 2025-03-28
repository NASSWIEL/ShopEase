// lib/widgets/article_ajoute_panier.dart (Corrected - No Navigation)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';

class ArticleAjoutePanier extends StatelessWidget {
  final CartItem cartItem;
  final String productId;

  const ArticleAjoutePanier({
    Key? key,
    required this.cartItem,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);

    return Dismissible(
      key: ValueKey(cartItem.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: const Icon(
          Icons.shopping_cart_checkout,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) { // Right Swipe - Buy Now
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Retirer du panier ?'),
              content: const Text(
                'Voulez-vous retirer cet article du panier ? ',
              ),
              actions: [
                TextButton(
                  child: const Text('Non'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                TextButton(
                  child: const Text('Oui'),
                  onPressed: () {
                    // TODO: Implement "Buy Now" logic here.
                    print('Buy now action for product ID: $productId');
                    // For now, let's simulate "buying" by clearing the cart:
                    cart.clear(); // Clear the cart on "Buy Now"
                    Navigator.of(ctx).pop(true); // Dismiss Dismissible
                  },
                ),
              ],
            ),
          );
        } else { // Left Swipe - Delete
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(' Acheter maintenant ?'),
              content: const Text(
                'Voulez-vous procéder à l\'achat de cet article ?',
              ),
              actions: [
                TextButton(
                  child: const Text('Non'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                TextButton(
                  child: const Text('Oui'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) { // Left Swipe - Delete
          cart.removeItem(productId); // Remove item from cart
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cartItem.title} retiré du panier'),
            ),
          );
        } else if (direction == DismissDirection.startToEnd) { // Right Swipe - Buy Now
          // Buy Now action is handled in confirmDismiss (cart.clear() is called there)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Achat simulé effectué! Panier vidé.'),
            ),
          );
        }
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
              backgroundImage: NetworkImage(
                cartItem.imageUrl,
              ),
            ),
            title: Text(cartItem.title),
            subtitle: Text(
              'Total: \$${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}',
            ),
            trailing: Text('${cartItem.quantity} x'),
          ),
        ),
      ),
    );
  }
}