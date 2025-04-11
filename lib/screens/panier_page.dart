import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../widgets/panier_vide_widget.dart';
import '../widgets/article_ajoute_panier.dart';
import './livraison_adresse_page.dart'; // Import the delivery address page

class PanierPage extends StatelessWidget {
  const PanierPage({Key? key}) : super(key: key);

  // Navigate to delivery address page
  void _navigateToDeliveryAddress(BuildContext context, {String? productId}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LivraisonAdressePage()),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        // Address was selected, show confirmation
        final address = result['address'];
        final location = result['location'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Livraison confirmée à: $address'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    });
  }

  Widget _buildCheckoutButton(BuildContext context, Cart cart) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5D9C88),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: cart.items.isEmpty
            ? null // Désactiver le bouton si le panier est vide
            : () {
                // Naviguer vers la page d'adresse de livraison avec le total du panier
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LivraisonAdressePage(
                      cartTotal: cart.totalAmount,
                    ),
                  ),
                );
              },
        child: const Text(
          'Procéder au paiement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: const Color(0xFF5D9C88),
      ),
      body: cart.items.isEmpty
          ? const PanierVideWidget()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      final productId = cart.items.keys.toList()[i];

                      return Dismissible(
                        key: ValueKey(productId),
                        background: Container(
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
                            size: 40,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          // Navigate to delivery address when swiped
                          _navigateToDeliveryAddress(
                            context,
                            productId: productId,
                          );
                          return false; // Don't actually dismiss the item
                        },
                        child: ArticleAjoutePanier(
                          cartItem: cartItem,
                          productId: productId,
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  margin: const EdgeInsets.all(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 20)),
                        const Spacer(),
                        Chip(
                          label: Text(
                            '\$${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF5D9C88),
                        ),
                        TextButton(
                          onPressed: () => _navigateToDeliveryAddress(context),
                          child: const Text('COMMANDER MAINTENANT'),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCheckoutButton(context, cart),
              ],
            ),
    );
  }
}
