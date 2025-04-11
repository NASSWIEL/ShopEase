import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DetailsArticlePage extends StatefulWidget {
  final String imageUrl;
  final Widget detailsWidget;

  const DetailsArticlePage({
    Key? key,
    required this.imageUrl,
    required this.detailsWidget,
  }) : super(key: key);

  @override
  _DetailsArticlePageState createState() => _DetailsArticlePageState();
}

class _DetailsArticlePageState extends State<DetailsArticlePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D9C88)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 55,
          colorFilter: null,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de l'article
          // SizedBox(
          //   width: double.infinity,
          //   height: MediaQuery.of(context).size.height * 0.4,
          //   child: Image.network(
          //     widget.imageUrl,
          //     fit: BoxFit.cover,
          //     loadingBuilder: (context, child, loadingProgress) {
          //       if (loadingProgress == null) return child;
          //       return Center(
          //         child: CircularProgressIndicator(
          //           value: loadingProgress.expectedTotalBytes != null
          //               ? loadingProgress.cumulativeBytesLoaded /
          //                   (loadingProgress.expectedTotalBytes ?? 1)
          //               : null,
          //           color: const Color(0xFF5D9C88),
          //         ),
          //       );
          //     },
          //     errorBuilder: (context, error, stackTrace) {
          //       return const Center(
          //         child: Column(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             Icon(Icons.error_outline, color: Colors.red, size: 40),
          //             SizedBox(height: 8),
          //             Text('Erreur de chargement d\'image',
          //                 style: TextStyle(color: Colors.red))
          //           ],
          //         ),
          //       );
          //     },
          //   ),
          // ),

          // Détails de l'article
          Expanded(
            child: widget.detailsWidget,
          ),
        ],
      ),
    );
  }
}
