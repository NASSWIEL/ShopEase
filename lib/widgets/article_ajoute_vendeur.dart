// lib/widgets/article_ajoute_vendeur.dart
import 'package:flutter/material.dart';
import '../models/produit_vendeur.dart';

class ArticleAjouteVendeur extends StatelessWidget {
  final String id;
  final String nom;
  final int quantite;
  final double prix;
  final String? imageUrl;
  final String? description;
  final String? barcode;

  const ArticleAjouteVendeur({
    Key? key,
    required this.id,
    required this.nom,
    required this.quantite,
    required this.prix,
    this.imageUrl,
    this.description,
    this.barcode,
  }) : super(key: key);

  // Named constructor to create from ProduitVendeur model
  factory ArticleAjouteVendeur.fromModel(ProduitVendeur produit) {
    return ArticleAjouteVendeur(
      id: produit.id,
      nom: produit.nom,
      quantite: produit.quantite,
      prix: produit.prix,
      imageUrl: produit.fullImageUrl,
      description: produit.description,
      barcode: produit.barcode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3.0,
      color:
          Colors.white, // White card background for better contrast with text
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image or placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print(
                              'Error loading image: $error for URL: $imageUrl');
                          return const Icon(Icons.broken_image,
                              color: Colors.grey, size: 40);
                        },
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2.0,
                            ),
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.inventory_2_outlined,
                      color: Colors.grey, size: 35),
            ),
            const SizedBox(width: 15),
            // Article information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C6149), // Dark green for title
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (description != null && description!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors
                              .black87, // Dark text on light background for maximum readability
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  // Price and quantity in a row for better organization
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prix: ${prix.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D9C88), // Green for price
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: quantite > 0
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: quantite > 0 ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Stock: $quantite',
                          style: TextStyle(
                            color: quantite > 0
                                ? Colors.green[900]
                                : Colors.red[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit icon
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5D9C88),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
