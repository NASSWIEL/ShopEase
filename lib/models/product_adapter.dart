import 'package:untitled/models/product.dart';
import 'package:untitled/models/produit_vendeur.dart';

/// Helper class to convert between different product models
class ProductAdapter {
  /// Converts a ProduitVendeur instance to a Product instance
  static Product fromProduitVendeur(ProduitVendeur produitVendeur) {
    return Product(
      id: produitVendeur.id.toString(),
      name: produitVendeur.nom,
      price:
          '${produitVendeur.prix} €', // Format the price as a string with euro symbol
      description: produitVendeur.description ?? 'No description available',
      imageUrl: produitVendeur.imageUrl ?? 'https://via.placeholder.com/400',
      // Add any additional properties from Product if needed
      specs: <String, String>{
        'Quantité': produitVendeur.quantite.toString(),
        'Barcode': produitVendeur.barcode ?? 'No barcode available',
      },
    );
  }
}
