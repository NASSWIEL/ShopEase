import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  // Dummy product list for demonstration purposes.
  final List<Map<String, String>> products = [
    {
      'name': 'Product 1',
      'price': '\$25.00',
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'name': 'Product 2',
      'price': '\$30.00',
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'name': 'Product 3',
      'price': '\$15.00',
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'name': 'Product 4',
      'price': '\$45.00',
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'name': 'Product 5',
      'price': '\$10.00',
      'imageUrl': 'https://via.placeholder.com/150',
    },
    {
      'name': 'Product 6',
      'price': '\$60.00',
      'imageUrl': 'https://via.placeholder.com/150',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5D9C88),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            );
          },
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 55, // Increased from 45
          colorFilter: null, // Remove color filter to use SVG's original colors
        ),
        actions: [
          
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF5D9C88)),
            onPressed: () {
              // TODO: Implement cart
            },
          ),
        ],
      ),
      drawer: Drawer(
        // TODO: Implement drawer content
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF5D9C88)),
              child: Text(
                'ShopEase Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        // Using GridView.builder to display products in a grid layout.
        child: GridView.builder(
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Display two products per row
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.7, // Adjust to fit your design
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                      child: Image.network(
                        product['imageUrl']!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Product Name
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Product Price
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      product['price']!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
