import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/screens/product_detail_page.dart';
import '../models/cart.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    // Show swipe hint briefly after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _showSwipeHint = true;
        });

        // Hide hint after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showSwipeHint = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragEnd: (details) {
            // If swiped left (negative velocity)
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailPage(product: widget.product),
                ),
              );
            }
          },
          child: Card(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with fixed dimensions
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Display a square placeholder when image fails to load
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Product Name with fixed height and better overflow protection
                SizedBox(
                  height: 42,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                    child: Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Product Price with overflow protection
                SizedBox(
                  height: 20,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                    child: Text(
                      widget.product.price,
                      style: const TextStyle(color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Add to Cart Button
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D9C88),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      onPressed: () {
                        // Add the item to cart
                        final cart = Provider.of<Cart>(context, listen: false);
                        cart.addItem(
                          widget.product.id,
                          widget.product.name,
                          double.parse(
                              widget.product.price.replaceAll('€', '')),
                          widget.product.imageUrl,
                        );

                        // Show a snackbar
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('${widget.product.name} added to cart!'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                cart.removeSingleItem(widget.product.id);
                              },
                            ),
                          ),
                        );
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ajouter au panier',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Swipe hint overlay
      ],
    );
  }
}
