// lib/screens/gestion_article_vendeur_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/article_ajoute_vendeur.dart';
import 'ajouter_article_vendeur_page.dart';
import 'editer_article_vendeur_page.dart';

// --- ProduitVendeur class definition (as before) ---
class ProduitVendeur { /* ... same as before ... */
  final String id;
  final String nom;
  final int quantite;
  final double prix;
  final String? barcode;
  final String? description;
  final String? imageUrl;

  ProduitVendeur({ required this.id, required this.nom, required this.quantite, required this.prix, this.barcode, this.description, this.imageUrl, });
  ProduitVendeur copyWith({ String? id, String? nom, int? quantite, double? prix, String? barcode, String? description, ValueGetter<String?>? imageUrlFn, }) {
    return ProduitVendeur( id: id ?? this.id, nom: nom ?? this.nom, quantite: quantite ?? this.quantite, prix: prix ?? this.prix, barcode: barcode ?? this.barcode, description: description ?? this.description, imageUrl: imageUrlFn != null ? imageUrlFn() : this.imageUrl, );
  }
}
// --- End of ProduitVendeur Definition ---


class GestionArticleVendeurPage extends StatefulWidget {
  const GestionArticleVendeurPage({Key? key}) : super(key: key);
  @override
  _GestionArticleVendeurPageState createState() => _GestionArticleVendeurPageState();
}

class _GestionArticleVendeurPageState extends State<GestionArticleVendeurPage> {
  // --- _produitsSource (sample data remains the same) ---
  final List<ProduitVendeur> _produitsSource = [ /* ... same sample data ... */
    ProduitVendeur( id: 'p1', nom: 'Fauxica Sport 1', quantite: 45, prix: 49.0, barcode: '123456789', description: 'Une description pour Fauxica 1', imageUrl: null ),
    ProduitVendeur( id: 'p2', nom: 'Fauxica Sport 2', quantite: 30, prix: 55.0, description: 'Autre description'),
    ProduitVendeur( id: 'p3', nom: 'Fauxica Sport 3', quantite: 10, prix: 42.0),
    ProduitVendeur( id: 'p4', nom: 'Montre Casio', quantite: 3, prix: 79.0, barcode: '987654321'),
    ProduitVendeur( id: 'p5', nom: 'Pantoufles', quantite: 1, prix: 12.0, description: 'Très confortables'),
  ];

  List<ProduitVendeur> _produitsFiltres = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _produitsFiltres = List.from(_produitsSource);
    _searchController.addListener(_filterProduits);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProduits);
    _searchController.dispose();
    super.dispose();
  }

  // --- _filterProduits (remains the same) ---
  void _filterProduits() { /* ... same as before ... */
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) { _produitsFiltres = List.from(_produitsSource); }
      else { _produitsFiltres = _produitsSource.where((p) => p.nom.toLowerCase().contains(query)).toList(); }
    });
  }

  // --- Add Article Dialog (MODIFIED the 'Avec code-barres' onPressed) ---
  void _ajouterArticle() async { // <-- Make the outer function async if needed, or handle inside
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          elevation: 5,
          backgroundColor: Colors.grey[200],
          child: Container(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text('Ajouter un article', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: 30),

                // Bouton "Avec un code-barres" (MODIFIED to await result)
                ElevatedButton(
                  onPressed: () async { // <-- Make this specific handler async
                    // FIRST: Close the dialog
                    Navigator.of(dialogContext).pop();

                    // SECOND: Navigate and AWAIT the result
                    final newProduct = await Navigator.push<ProduitVendeur>( // Expect a ProduitVendeur back
                      context, // Use the main page context
                      MaterialPageRoute(builder: (context) => const AjouterArticleVendeurPage()),
                    );

                    // THIRD: Handle the result
                    if (newProduct != null && mounted) {
                      setState(() {
                        // Add to the *source* list
                        _produitsSource.insert(0, newProduct); // Add to beginning for visibility
                        // Refresh the filtered list
                        _filterProduits();
                        print("New product added: ${newProduct.nom}");
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Article "${newProduct.nom}" ajouté.'))
                        );
                      });
                    } else {
                      print("Add page returned null or widget unmounted.");
                    }
                  }, // <-- End of async onPressed
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14)),
                  child: const Text('Avec un code-barres'),
                ),
                const SizedBox(height: 15),

                // Bouton "Sans code-barres" (Placeholder - remains the same)
                ElevatedButton(
                  onPressed: () { /* ... placeholder code ... */
                    print('Option "Sans code-barres" sélectionnée');
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajout sans code-barres à implémenter')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14)),
                  child: const Text('Sans code-barres'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- End of Add Article Dialog ---


  // --- _navigateToEditPage (remains the same) ---
  void _navigateToEditPage(ProduitVendeur produitToEdit) async { /* ... same as before ... */
    final updatedProduit = await Navigator.push<ProduitVendeur>( context, MaterialPageRoute( builder: (context) => EditerArticleVendeurPage(produit: produitToEdit), ), );
    if (updatedProduit != null && mounted) {
      setState(() {
        int index = _produitsSource.indexWhere((p) => p.id == updatedProduit.id);
        if (index != -1) { _produitsSource[index] = updatedProduit; _filterProduits(); print("Product updated: ${updatedProduit.nom}"); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Article "${updatedProduit.nom}" mis à jour.')) ); }
        else { print("Error: Could not find product with ID ${updatedProduit.id} to update."); ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Erreur: Article non trouvé pour la mise à jour.')) ); }
      });
    } else { print("Edit page returned null (cancelled or no changes saved)."); }
  }
  // --- End of Navigation Function ---


  @override
  Widget build(BuildContext context) {
    // --- Build method remains the same as in the previous step ---
    // It correctly uses _produitsFiltres for the ListView.builder
    // and _navigateToEditPage in the InkWell onTap.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar( /* ... */
        backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF5D9C88)), onPressed: () => Navigator.of(context).pop()), centerTitle: true, title: SvgPicture.asset('assets/images/logo.svg', height: 55),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15), const Text('Gestion articles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 15),
              Container( /* Search Bar */ height: 45, decoration: BoxDecoration( color: const Color(0xFFF5F5DC), borderRadius: BorderRadius.circular(25.0), border: Border.all(color: Colors.grey.shade300) ), child: Padding( padding: const EdgeInsets.symmetric(horizontal: 15.0), child: TextField( controller: _searchController, decoration: const InputDecoration( hintText: 'Rechercher un article...', border: InputBorder.none, icon: Icon(Icons.search, color: Colors.grey), hintStyle: TextStyle(color: Colors.grey) ) ) ) ), const SizedBox(height: 20),
              Expanded( /* List Container */
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration( color: const Color(0xFF5D9C88).withOpacity(0.9), borderRadius: BorderRadius.circular(20.0), ),
                  child: _produitsFiltres.isEmpty
                      ? Center( child: Text( _searchController.text.isEmpty ? 'Aucun article à gérer.' : 'Aucun article trouvé pour "${_searchController.text}"', style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center, ) )
                      : ListView.builder(
                    itemCount: _produitsFiltres.length,
                    itemBuilder: (context, index) {
                      final produit = _produitsFiltres[index];
                      return InkWell( onTap: () { _navigateToEditPage(produit); }, child: ArticleAjouteVendeur( nom: produit.nom, quantite: produit.quantite, prix: produit.prix, /* imageUrl: produit.imageUrl, */ ), );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon( /* Add Button */
                onPressed: _ajouterArticle, icon: const Icon(Icons.add, color: Colors.white), label: const Text('Ajouter Article', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom( backgroundColor: const Color(0xFF5D9C88), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(15.0), ), elevation: 5, ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}