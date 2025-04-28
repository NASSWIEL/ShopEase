import 'package:flutter/material.dart';
import 'package:shopease/screens/livraison_adresse_page.dart';
import 'package:provider/provider.dart';
import 'package:shopease/models/cart.dart';
import 'package:shopease/models/cart_item.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Calculate the total cart value
  double calculateTotal(List<CartItem> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      total += item.price * item.quantity;
    }
    print("Calculated cart total: $total");
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: const Color(0xFF5D9C88),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Add items to get started!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(8),
                        image:
                            item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(item.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                          ? const Icon(Icons.shopping_bag,
                              color: Color(0xFF5D9C88))
                          : null,
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Text('Quantity: ${item.quantity}'),
                        const Spacer(),
                        // Add quantity controls
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {
                            if (item.quantity > 1) {
                              cart.decrementQuantity(item.id);
                            } else {
                              // Show confirmation dialog before removing
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove item?'),
                                  content: const Text(
                                      'Do you want to remove this item from the cart?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        cart.removeItem(item.id);
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => cart.incrementQuantity(item.id),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${item.price} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF5D9C88),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${calculateTotal(cartItems).toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D9C88),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      double cartTotal = calculateTotal(cartItems);
                      print(
                          "Navigating to delivery address page with cart total: $cartTotal");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LivraisonAdressePage(
                            cartTotal: cartTotal,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D9C88),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
