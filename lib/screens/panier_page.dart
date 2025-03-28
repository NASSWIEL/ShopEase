import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../widgets/panier_vide_widget.dart'; // Import the PanierVideWidget

class PanierPage extends StatelessWidget {
  const PanierPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: const Color(0xFF5D9C88),
      ),
      body:
      cart.items.isEmpty
          ? const PanierVideWidget() // Use PanierVideWidget when cart is empty
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItem = cart.items.values.toList()[i];
                final productId = cart.items.keys.toList()[i];

                return Dismissible(
                  key: ValueKey(cartItem.id),
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
                      size: 30,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    cart.removeItem(productId);
                  },
                  confirmDismiss: (direction) {
                    return showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                        title: const Text('Êtes-vous sûr?'),
                        content: const Text(
                          'Voulez-vous retirer cet article du panier?',
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
                    onPressed: () {
                      // Handle checkout process
                    },
                    child: const Text('COMMANDER MAINTENANT'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}