import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../widgets/panier_vide_widget.dart';
import '../widgets/article_ajoute_panier.dart';
import './livraison_adresse_page.dart'; // Import the delivery address page
import '../services/api_service.dart'; // Import API service for product info
import '../models/produit_vendeur.dart'; // Import product model

class PanierPage extends StatefulWidget {
  const PanierPage({super.key}); // Updated to use super.key

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  final Map<String, int> _productStockLimits = {};
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch stock information for cart items
    _fetchStockInfo();
  }

  // Fetch stock information for products in the cart
  Future<void> _fetchStockInfo() async {
    final cart = Provider.of<Cart>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch stock info for each product in the cart
      for (final productId in cart.items.keys) {
        try {
          final product = await _apiService.getProductById(productId);

          // Update cart's stock limit information
          cart.setStockLimit(productId, product.quantite);

          // Also store locally for display
          setState(() {
            _productStockLimits[productId] = product.quantite;
          });
        } catch (e) {
          print('Error fetching stock for product $productId: $e');
          // Continue with other products even if one fails
        }
      }
    } catch (e) {
      print('Error fetching stock info: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to delivery address page
  void _navigateToDeliveryAddress(BuildContext context, {String? productId}) {
    final cart = Provider.of<Cart>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              LivraisonAdressePage(cartTotal: cart.totalAmount)),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        // Address was selected, show confirmation
        final address = result['address'];
        // Removed unused location variable

        // Verify context is still valid before using it
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Livraison confirmée à: $address'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        }
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

    // If cart items changed, fetch stock info for new items
    if (cart.items.isNotEmpty) {
      for (final productId in cart.items.keys) {
        if (!_productStockLimits.containsKey(productId)) {
          // Fetch stock info for this product if we don't have it yet
          _fetchStockInfo();
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: const Color(0xFF5D9C88),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
              ? const PanierVideWidget()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) {
                          final cartItem = cart.items.values.toList()[i];
                          final productId = cart.items.keys.toList()[i];
                          final stockLimit = _productStockLimits[productId];

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
                            // Updated to pass stock limit to article_ajoute_panier
                            child: ArticleAjoutePanier(
                              productId: productId,
                              productName: cartItem.name,
                              price: cartItem.price,
                              quantity: cartItem.quantity,
                              imageUrl: cartItem.imageUrl,
                              stockLimit: stockLimit,
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
                              onPressed: () =>
                                  _navigateToDeliveryAddress(context),
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
