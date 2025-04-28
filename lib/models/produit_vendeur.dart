import 'package:shopease/config/network_config.dart';

class ProduitVendeur {
  final String? id; // Keep as int? for internal usage
  final String? idString; // Added string representation for API calls
  final String nom;
  final String? description;
  final double prix;
  final int quantite;
  final String? barcode;
  String? imageUrl;
  final int? vendorId;

  var fullImageUrl;

  ProduitVendeur({
    this.id,
    this.idString,
    required this.nom,
    this.description,
    required this.prix,
    required this.quantite,
    this.barcode,
    this.imageUrl,
    this.vendorId,
  });

  // Factory constructor to create a product from JSON
  factory ProduitVendeur.fromJson(Map<String, dynamic> json) {
    // Print the raw JSON for debugging
    print('Processing product JSON: $json');

    // Handle image URL - normalize to absolute URL if relative
    String? imageUrl = json['image_url'] ?? json['image'];
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      imageUrl = '${NetworkConfig.baseApiUrl}$imageUrl';
      print('Normalized image URL: $imageUrl');
    }

    // Handle different ID formats (string or int)
    String? id;
    String? idString;

    if (json['id'] != null) {
      if (json['id'] is String) {
        idString = json['id'];
        id = json['id'] is String ? json['id'] : null;
      } else if (json['id'] is int) {
        id = json['id'];
        idString = id.toString();
      }
    }

    // Handle different price formats (string or double or int)
    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        price = double.tryParse(json['price']) ?? 0.0;
      } else if (json['price'] is int) {
        price = (json['price'] as int).toDouble();
      } else if (json['price'] is double) {
        price = json['price'];
      }
    }

    // Handle different quantity formats (string or int)
    int quantity = 0;
    if (json['stock'] != null) {
      quantity = json['stock'] is String
          ? int.tryParse(json['stock']) ?? 0
          : json['stock'] as int;
    }

    // Handle vendor_id
    int? vendorId;
    if (json['vendor_id'] != null) {
      vendorId = json['vendor_id'] is String
          ? int.tryParse(json['vendor_id'])
          : json['vendor_id'] as int?;
    }

    return ProduitVendeur(
      id: id,
      idString: idString,
      // Handle different field names for name/nom
      nom: json['name'] ?? json['nom'] ?? 'Unnamed Product',
      description: json['description'],
      prix: price,
      quantite: quantity,
      barcode: json['barcode'],
      imageUrl: imageUrl,
      vendorId: vendorId,
    );
  }

  // Convert product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': idString ?? id?.toString(),
      'name': nom,
      'description': description ?? '',
      'price': prix,
      'stock': quantite,
      'barcode': barcode ?? '',
      'image_url': imageUrl ?? '',
      'vendor_id': vendorId,
    };
  }

  // Add copyWith method to create a copy with modified fields
  ProduitVendeur copyWith({
    String? idString,
    String? nom,
    String? description,
    double? prix,
    int? quantite,
    String? barcode,
    String? imageUrl,
    int? vendorId,
  }) {
    return ProduitVendeur(
      id: this.id,
      idString: idString ?? this.idString,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      vendorId: vendorId ?? this.vendorId,
    );
  }
}
