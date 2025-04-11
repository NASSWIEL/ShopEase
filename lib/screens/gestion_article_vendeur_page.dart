// lib/screens/gestion_article_vendeur_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/barcode_scanner_service.dart';
import '../widgets/article_ajoute_vendeur.dart';
import 'ajouter_article_vendeur_page.dart';
import 'editer_article_vendeur_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connexion_page.dart';
import '../models/produit_vendeur.dart';

class GestionArticleVendeurPage extends StatefulWidget {
  const GestionArticleVendeurPage({Key? key}) : super(key: key);
  @override
  _GestionArticleVendeurPageState createState() =>
      _GestionArticleVendeurPageState();
}

class _GestionArticleVendeurPageState extends State<GestionArticleVendeurPage> {
  // Sample data using the imported model
  final List<ProduitVendeur> _produitsSource = [
    ProduitVendeur(
        id: 'p1',
        nom: 'Fauxica Sport 1',
        quantite: 45,
        prix: 49.0,
        barcode: '123456789',
        description: 'Une description pour Fauxica 1',
        imageUrl: null),
    ProduitVendeur(
        id: 'p2',
        nom: 'Fauxica Sport 2',
        quantite: 30,
        prix: 55.0,
        description: 'Autre description'),
    ProduitVendeur(id: 'p3', nom: 'Fauxica Sport 3', quantite: 10, prix: 42.0),
    ProduitVendeur(
        id: 'p4',
        nom: 'Montre Casio',
        quantite: 3,
        prix: 79.0,
        barcode: '987654321'),
    ProduitVendeur(
        id: 'p5',
        nom: 'Pantoufles',
        quantite: 1,
        prix: 12.0,
        description: 'Très confortables'),
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

  void _filterProduits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _produitsFiltres = List.from(_produitsSource);
      } else {
        _produitsFiltres = _produitsSource
            .where((p) => p.nom.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _ajouterArticle() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          elevation: 5,
          backgroundColor: Colors.grey[200],
          child: Container(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text('Ajouter un article',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(true); // Return true to indicate barcode
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 14)),
                  child: const Text('Avec un code-barres'),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(false); // Return false to indicate no barcode
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 14)),
                  child: const Text('Sans code-barres'),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Handle dialog result
    if (result != null && mounted) {
      String? barcode;

      // If user chose to add with barcode, scan it first
      if (result == true) {
        barcode = await _scanBarcode();
        if (barcode == '-1') {
          // User canceled scan
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scan annulé')),
          );
          return;
        }
      }

      // Navigate to add article page, passing the barcode if available
      final newProduct = await Navigator.push<ProduitVendeur>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AjouterArticleVendeurPage(initialBarcode: barcode),
        ),
      );

      if (newProduct != null && mounted) {
        setState(() {
          _produitsSource.insert(0, newProduct);
          _filterProduits();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Article "${newProduct.nom}" ajouté.')),
          );
        });
      }
    }
  }

  Future<String> _scanBarcode() async {
    // Use our simplified service which doesn't rely on native plugins
    return await BarcodeScannerService.scanBarcode(context);
  }

  void _navigateToEditPage(ProduitVendeur produitToEdit) async {
    final updatedProduit = await Navigator.push<ProduitVendeur>(
      context,
      MaterialPageRoute(
        builder: (context) => EditerArticleVendeurPage(produit: produitToEdit),
      ),
    );

    if (updatedProduit != null && mounted) {
      setState(() {
        // Find the index of the product with matching ID
        final index =
            _produitsSource.indexWhere((p) => p.id == updatedProduit.id);

        if (index != -1) {
          _produitsSource[index] = updatedProduit;
          _filterProduits(); // Update the filtered list

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Article "${updatedProduit.nom}" mis à jour.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Erreur: Article non trouvé pour la mise à jour.')),
          );
        }
      });
    }
  }

  void _confirmDeleteArticle(ProduitVendeur produit) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'article "${produit.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      setState(() {
        _produitsSource.removeWhere((p) => p.id == produit.id);
        _filterProduits();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article "${produit.nom}" supprimé.')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: SvgPicture.asset('assets/images/logo.svg', height: 55),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF5D9C88)),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Se déconnecter?'),
                  content:
                      const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Déconnexion',
                          style: TextStyle(color: Color(0xFF5D9C88))),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('currentUser');
                await prefs.remove('currentUserType');

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ConnexionPage()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),
              const Text('Gestion articles',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 15),
              Container(
                  height: 45,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F5DC),
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                              hintText: 'Rechercher un article...',
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintStyle: TextStyle(color: Colors.grey))))),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D9C88).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: _produitsFiltres.isEmpty
                      ? Center(
                          child: Text(
                          _searchController.text.isEmpty
                              ? 'Aucun article à gérer.'
                              : 'Aucun article trouvé pour "${_searchController.text}"',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ))
                      : ListView.builder(
                          itemCount: _produitsFiltres.length,
                          itemBuilder: (context, index) {
                            final produit = _produitsFiltres[index];
                            return Dismissible(
                              key: Key(produit.id),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                          "Confirmer la suppression"),
                                      content: Text(
                                          "Êtes-vous sûr de vouloir supprimer l'article \"${produit.nom}\"?"),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("ANNULER"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("SUPPRIMER",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) {
                                setState(() {
                                  _produitsSource
                                      .removeWhere((p) => p.id == produit.id);
                                  _filterProduits();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Article "${produit.nom}" supprimé')),
                                  );
                                });
                              },
                              child: InkWell(
                                onTap: () => _navigateToEditPage(produit),
                                child: ArticleAjouteVendeur.fromModel(produit),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _ajouterArticle,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Ajouter Article',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D9C88),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
