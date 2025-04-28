// lib/screens/gestion_article_vendeur_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/article_ajoute_vendeur.dart';
import 'ajouter_article_vendeur_page.dart';
import 'editer_article_vendeur_page.dart';
import 'barcode_scanner_page.dart'; // Import the barcode scanner page
import 'package:shared_preferences/shared_preferences.dart';
import '../models/produit_vendeur.dart';
import '../services/api_service.dart'; // Import API service
import 'package:shopease/widgets/profile_logout_widget.dart'; // Import the profile widget

class GestionArticleVendeurPage extends StatefulWidget {
  const GestionArticleVendeurPage({Key? key}) : super(key: key);
  @override
  _GestionArticleVendeurPageState createState() =>
      _GestionArticleVendeurPageState();
}

class _GestionArticleVendeurPageState extends State<GestionArticleVendeurPage> {
  // List to hold products from the database
  List<ProduitVendeur> _produitsSource = [];
  List<ProduitVendeur> _produitsFiltres = [];
  final TextEditingController _searchController = TextEditingController();

  // API service instance
  final ApiService _apiService = ApiService();

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProduits);
    // Fetch products from the API when the page loads
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProduits);
    _searchController.dispose();
    super.dispose();
  }

  // Method to fetch products from the API
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call the API service to get products
      final products = await _apiService.getVendorProducts();

      if (mounted) {
        setState(() {
          _produitsSource = products;
          _produitsFiltres = List.from(products);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: $e';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la récupération des produits: $e')),
        );
      }
    }
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
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Avec un code',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14)),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 14)),
                  child: const Text('Sans code'),
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

      // If user chose to add with code, get it via manual input
      if (result == true) {
        barcode = await _inputBarcode();
        if (barcode == '-1') {
          // User canceled input
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saisie de code annulée')),
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article "${newProduct.nom}" ajouté.')),
        );
      }
    }
  }

  Future<String> _inputBarcode() async {
    try {
      // Utiliser le scanner de code-barres de la bibliothèque mobile_scanner
      String? result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => BarcodeScannerPage()),
      );

      // Si le résultat est null ou vide, considérez-le comme annulé
      if (result == null || result.isEmpty || result == '-1') {
        return '-1';
      }

      print('Code-barres scanné: $result');
      return result;
    } catch (e) {
      print('Erreur lors du scan du code-barres: $e');
      // En cas d'erreur, revenir à la saisie manuelle
      return _manualCodeInput();
    }
  }

  // Méthode de secours pour la saisie manuelle du code
  Future<String> _manualCodeInput() async {
    final TextEditingController codeController = TextEditingController();
    final Completer<String> completer = Completer<String>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Saisir un code manuellement'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              hintText: "Entrez le code du produit",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
                completer.complete('-1');
              },
            ),
            TextButton(
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop();
                if (codeController.text.trim().isEmpty) {
                  completer.complete('-1');
                } else {
                  completer.complete(codeController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  void _navigateToEditPage(ProduitVendeur produitToEdit) async {
    // Before navigating, log the product details to debug
    print('Editing product with barcode: ${produitToEdit.barcode}');

    final updatedProduit = await Navigator.push<ProduitVendeur>(
      context,
      MaterialPageRoute(
        builder: (context) => EditerArticleVendeurPage(produit: produitToEdit),
      ),
    );

    if (updatedProduit != null && mounted) {
      // Log the updated product to check if barcode is preserved
      print('Updated product barcode: ${updatedProduit.barcode}');

      setState(() {
        // Find the index of the product with matching ID
        final index =
            _produitsSource.indexWhere((p) => p.id == updatedProduit.id);

        if (index != -1) {
          _produitsSource[index] = updatedProduit;
          _filterProduits(); // Update the filtered list
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article "${updatedProduit.nom}" mis à jour.')),
      );
    }
  }

  Future<void> _deleteArticle(ProduitVendeur produit) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the API service to delete the product
      await _apiService.deleteProduct(produit.id.toString());

      if (mounted) {
        setState(() {
          _produitsSource.removeWhere((p) => p.id == produit.id);
          _produitsFiltres.removeWhere((p) => p.id == produit.id);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article "${produit.nom}" supprimé.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
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
      _deleteArticle(produit);
    }
  }

  // Pull to refresh functionality
  Future<void> _refreshProducts() async {
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Gestion des Articles',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: const Color(0xFF2C6149),
        actions: const [
          // Add the profile logout widget to the app bar
          ProfileLogoutWidget(),
          SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF5D9C88)),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red, size: 60),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchProducts,
                                  child: const Text('Réessayer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5D9C88),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshProducts,
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
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: _produitsFiltres.length,
                                      itemBuilder: (context, index) {
                                        final produit = _produitsFiltres[index];
                                        return Dismissible(
                                          key: Key(produit.id.toString()),
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 20),
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          direction:
                                              DismissDirection.endToStart,
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
                                                          Navigator.of(context)
                                                              .pop(false),
                                                      child:
                                                          const Text("ANNULER"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(true),
                                                      child: const Text(
                                                          "SUPPRIMER",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          onDismissed: (direction) {
                                            _deleteArticle(produit);
                                          },
                                          child: InkWell(
                                            onTap: () =>
                                                _navigateToEditPage(produit),
                                            child:
                                                ArticleAjouteVendeur.fromModel(
                                                    produit),
                                          ),
                                        );
                                      },
                                    ),
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
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
