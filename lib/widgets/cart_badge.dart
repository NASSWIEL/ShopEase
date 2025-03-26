import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../screens/panier_page.dart'; // Make sure this import matches your project structure

class CartBadge extends StatelessWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(
      builder:
          (_, cart, child) => Badge(
            alignment: AlignmentDirectional.topEnd,
            label: Text(
              cart.itemCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, color: Color(0xFF5D9C88)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PanierPage()),
                );
              },
            ),
          ),
    );
  }
}
