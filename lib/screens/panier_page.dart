import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../widgets/panier_vide_widget.dart';
import '../widgets/article_ajoute_panier.dart'; // Import ArticleAjoutePanier

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

                return ArticleAjoutePanier( // Use ArticleAjoutePanier here
                  cartItem: cartItem,
                  productId: productId,
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