import 'package:untitled/config/network_config.dart';

class ProduitVendeur {
  final String id;
  final String nom;
  final int quantite;
  final double prix;
  final String? barcode;
  final String? description;
  final String? imageUrl; // Store the raw image URL as received from API

  ProduitVendeur({
    required this.id,
    required this.nom,
    required this.quantite,
    required this.prix,
    this.barcode,
    this.description,
    this.imageUrl,
  });

  // Factory constructor to create a ProduitVendeur from JSON data
  factory ProduitVendeur.fromJson(Map<String, dynamic> json) {
    return ProduitVendeur(
      id: json['id'] ?? '',
      nom: json['name'] ?? '',
      quantite: json['stock'] ?? 0,
      prix: (json['price'] ?? 0.0).toDouble(),
      barcode: json['barcode'],
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  // Get the full image URL that can be used by Image.network()
  String? get fullImageUrl {
    return imageUrl != null ? NetworkConfig.getImageUrl(imageUrl) : null;
  }

  // Create a copy of this product with modified properties
  ProduitVendeur copyWith({
    String? id,
    String? nom,
    int? quantite,
    double? prix,
    String? barcode,
    String? description,
    String? imageUrl,
  }) {
    return ProduitVendeur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      quantite: quantite ?? this.quantite,
      prix: prix ?? this.prix,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
