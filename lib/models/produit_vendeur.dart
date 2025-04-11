class ProduitVendeur {
  final String id;
  final String nom;
  final int quantite;
  final double prix;
  final String? barcode;
  final String? description;
  final String? imageUrl;

  ProduitVendeur({
    required this.id,
    required this.nom,
    required this.quantite,
    required this.prix,
    this.barcode,
    this.description,
    this.imageUrl,
  });

  ProduitVendeur copyWith({
    String? id,
    String? nom,
    int? quantite,
    double? prix,
    String? barcode,
    String? description,
    ValueGetter<String?>? imageUrlFn,
  }) {
    return ProduitVendeur(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      quantite: quantite ?? this.quantite,
      prix: prix ?? this.prix,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      imageUrl: imageUrlFn != null ? imageUrlFn() : this.imageUrl,
    );
  }
}

// Added for the copyWith method
typedef ValueGetter<T> = T Function();
