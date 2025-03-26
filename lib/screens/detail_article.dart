import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import 'panier_page.dart';

class DetailArticle extends StatefulWidget {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String description;

  const DetailArticle({
    Key? key,
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  }) : super(key: key);

  @override
  State<DetailArticle> createState() => _DetailArticleState();
}

class _DetailArticleState extends State<DetailArticle> {
  int quantity = 1;

  void onAddToCart() {
    // Get the cart from provider
    final cart = Provider.of<Cart>(context, listen: false);

    // Parse the price (removing $ symbol)
    final price = double.parse(widget.price.replaceAll('\$', ''));

    // Use the addItems method to add products with quantity
    cart.addItems(widget.id, widget.name, price, widget.imageUrl, quantity);

    // Show feedback to user with a snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.name} ajouté au panier!'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.price,
                    style: const TextStyle(fontSize: 20, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Quantité:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D9C88),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    onAddToCart();
                  },
                  child: const Text(
                    'Ajouter au panier',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  onAddToCart();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PanierPage()),
                  );
                },
                child: const Text(
                  'Acheter maintenant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
