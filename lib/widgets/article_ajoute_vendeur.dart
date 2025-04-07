// lib/widgets/article_ajoute_vendeur.dart
import 'package:flutter/material.dart';

class ArticleAjouteVendeur extends StatelessWidget {
  final String nom;
  final int quantite;
  final double prix;
  // Optionnel: vous pouvez ajouter un imageUrl si vous voulez afficher une vraie image plus tard
  // final String? imageUrl;

  const ArticleAjouteVendeur({
    Key? key,
    required this.nom,
    required this.quantite,
    required this.prix,
    // this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC), // Couleur beige clair pour l'élément
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        children: [
          // Placeholder pour l'image (le rectangle beige clair dans votre image)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // Couleur un peu plus claire ou différente
              borderRadius: BorderRadius.circular(8.0),
            ),
            // Plus tard, vous pourrez remplacer ceci par:
            // child: imageUrl != null
            //     ? Image.network(imageUrl!, fit: BoxFit.cover)
            //     : const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          // Nom et Quantité
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantité: $quantite',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Prix
          Text(
            '${prix.toStringAsFixed(0)}€', // Affichage du prix sans décimales avec le symbole €
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}