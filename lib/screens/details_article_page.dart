import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:untitled/widgets/details_article.dart';

class DetailsArticlePage extends StatelessWidget {
  final String imageUrl;
  final Widget detailsWidget;

  const DetailsArticlePage({
    Key? key,
    required this.imageUrl,
    required this.detailsWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF5D9C88),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 55,
          colorFilter: null,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF5D9C88)),
            onPressed: () {
              print('Panier cliqué depuis la page de détails');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            detailsWidget, // Affichage du widget de détails
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
