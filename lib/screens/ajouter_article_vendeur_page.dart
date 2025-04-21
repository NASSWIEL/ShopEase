// lib/screens/ajouter_article_vendeur_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:typed_data';
import '../models/produit_vendeur.dart';
import '../services/barcode_scanner_service.dart';
import '../services/api_service.dart'; // Ajout du service API

class AjouterArticleVendeurPage extends StatefulWidget {
  final String? initialBarcode;

  const AjouterArticleVendeurPage({Key? key, this.initialBarcode})
      : super(key: key);

  @override
  _AjouterArticleVendeurPageState createState() =>
      _AjouterArticleVendeurPageState();
}

class _AjouterArticleVendeurPageState extends State<AjouterArticleVendeurPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  XFile? _pickedImage;
  Future<Uint8List>? _webImageFuture; // For web preview

  // Instances du service API
  final ApiService _apiService = ApiService();

  // État de chargement de la requête API
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // If initialBarcode is provided, populate the barcode field
    if (widget.initialBarcode != null && widget.initialBarcode != '-1') {
      _barcodeController.text = widget.initialBarcode!;

      // Fetch product details using our service
      _fetchProductDetails(widget.initialBarcode!);
    }
  }

  // Fetch product details from our service
  Future<void> _fetchProductDetails(String barcode) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add a small delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 300));

      // Get product info from our service
      final productData = BarcodeScannerService.getProductInfo(barcode);

      if (productData != null && mounted) {
        // Populate fields with the product data
        _nameController.text = productData['name'] ?? '';
        _priceController.text = productData['price'] ?? '';
        _descriptionController.text = productData['description'] ?? '';

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Détails trouvés pour le code-barres: $barcode')));
      } else if (mounted) {
        // No data found for this barcode
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Aucune information trouvée pour le code-barres: $barcode')));
      }
    } catch (e) {
      print('Error fetching product details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Erreur lors de la recherche des détails du produit: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add a loading state variable
  bool _isLoading = false;

  // --- Image Picking Logic (_pickImage remains the same) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          if (kIsWeb) {
            _webImageFuture = pickedFile.readAsBytes();
          }
        });
        print('New image picked: ${pickedFile.path}');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection d\'image: $e')),
        );
      }
    }
  }

  // --- Save Article Logic (MISE À JOUR pour utiliser l'API) ---
  Future<void> _saveArticle() async {
    // Optional: Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Get values from controllers
    final name = _nameController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le nom de l\'article est requis.')));
      return;
    }
    final barcode = _barcodeController.text;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final description = _descriptionController.text;

    // Create product object
    final ProduitVendeur newProduct = ProduitVendeur(
      id: '', // L'ID sera généré par le backend
      nom: name,
      quantite: quantity,
      prix: price,
      barcode: barcode.isEmpty ? null : barcode,
      description: description.isEmpty ? null : description,
      imageUrl: null, // L'URL de l'image sera générée par le backend
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Call API to add product with image
      final ProduitVendeur addedProduct = await _apiService.addProduct(
        newProduct,
        imageFile: _pickedImage,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article ajouté avec succès')));

        // Return to previous screen with new product
        Navigator.of(context).pop(addedProduct);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });

        // Show error message
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $_errorMessage')));
      }
    }
  }
  // --- End of Save Article Logic ---

  // --- Helper Widget to Build Image Preview (_buildImagePreview remains the same) ---
  Widget _buildImagePreview() {
    if (_pickedImage != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _webImageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
            } else if (snapshot.hasError) {
              print("Error loading web image bytes: ${snapshot.error}");
              return const Icon(Icons.broken_image,
                  color: Colors.grey, size: 40);
            } else if (snapshot.hasData) {
              return Image.memory(snapshot.data!,
                  fit: BoxFit.cover, height: 100, width: 100);
            } else {
              return const Icon(Icons.image_not_supported,
                  color: Colors.grey, size: 40);
            }
          },
        );
      } else {
        try {
          return Image.file(File(_pickedImage!.path),
              fit: BoxFit.cover,
              height: 100,
              width: 100, errorBuilder: (context, error, stackTrace) {
            print("Error displaying newly picked file image: $error");
            return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
          });
        } catch (e) {
          print("Error creating Image.file for picked image: $e");
          return const Icon(Icons.error_outline, color: Colors.red, size: 40);
        }
      }
    }
    // Placeholder if no image is picked
    return Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40);
  }
  // --- End of Image Preview ---

  @override
  Widget build(BuildContext context) {
    const Color inputFillColor = Color(0xFFF5F5DC);
    const Color darkContainerColor = Color(0xFF424242);
    const Color labelColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        /* ... AppBar code ... */
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5D9C88)),
            onPressed: () =>
                Navigator.of(context).pop()), // Just pop on back press
        centerTitle: true,
        title: SvgPicture.asset('assets/images/logo.svg', height: 55),
      ),
      body: _isLoading || _isSubmitting
          ? const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF5D9C88)),
                SizedBox(height: 16),
                Text("Traitement en cours..."),
              ],
            ))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Afficher le message d'erreur s'il y en a un
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.red.shade700,
                              onPressed: () =>
                                  setState(() => _errorMessage = null),
                            )
                          ],
                        ),
                      ),

                    Container(
                      /* ... Main Dark Container ... */
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                          color: darkContainerColor,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3))
                          ]),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Center(
                                child: Text('AJOUTER UN ARTICLE',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.1),
                                    textAlign: TextAlign.center)),
                            const SizedBox(height: 30),

                            // --- Input Fields ---
                            // Code-barre
                            const Text('Code-barre:',
                                style: TextStyle(color: labelColor)),
                            const SizedBox(height: 5),
                            TextFormField(
                                controller: _barcodeController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFillColor,
                                    hintText:
                                        'Entrez le code-barre', // Added hint
                                    hintStyle: TextStyle(
                                        color: Colors
                                            .grey[600]), // Added hint style
                                    enabledBorder: OutlineInputBorder(
                                      // Added border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      // Added focused border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF5D9C88), width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      // Keep consistent border
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12))), // Adjusted padding
                            const SizedBox(height: 15),
                            // Nom d'article
                            const Text('Nom d\'article:',
                                style: TextStyle(color: labelColor)),
                            const SizedBox(height: 5),
                            TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFillColor,
                                    hintText:
                                        'Entrez le nom de l\'article', // Added hint
                                    hintStyle: TextStyle(
                                        color: Colors
                                            .grey[600]), // Added hint style
                                    enabledBorder: OutlineInputBorder(
                                      // Added border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      // Added focused border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF5D9C88), width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12))), // Adjusted padding
                            const SizedBox(height: 15),
                            // Quantité
                            const Text('Quantité:',
                                style: TextStyle(color: labelColor)),
                            const SizedBox(height: 5),
                            TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFillColor,
                                    hintText:
                                        'Entrez la quantité', // Added hint
                                    hintStyle: TextStyle(
                                        color: Colors
                                            .grey[600]), // Added hint style
                                    enabledBorder: OutlineInputBorder(
                                      // Added border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      // Added focused border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF5D9C88), width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12))), // Adjusted padding
                            const SizedBox(height: 15),
                            // Prix unitaire
                            const Text('Prix unitaire:',
                                style: TextStyle(color: labelColor)),
                            const SizedBox(height: 5),
                            TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'))
                                ],
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFillColor,
                                    hintText:
                                        'Entrez le prix (ex: 12.99)', // Added hint
                                    hintStyle: TextStyle(
                                        color: Colors
                                            .grey[600]), // Added hint style
                                    enabledBorder: OutlineInputBorder(
                                      // Added border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      // Added focused border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF5D9C88), width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12))), // Adjusted padding
                            const SizedBox(height: 15),
                            // Description
                            const Text('Description:',
                                style: TextStyle(color: labelColor)),
                            const SizedBox(height: 5),
                            TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFillColor,
                                    hintText:
                                        'Entrez une description (optionnel)', // Added hint
                                    hintStyle: TextStyle(
                                        color: Colors
                                            .grey[600]), // Added hint style
                                    enabledBorder: OutlineInputBorder(
                                      // Added border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide:
                                          BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      // Added focused border style
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF5D9C88), width: 1.5),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 12))), // Adjusted padding
                            const SizedBox(height: 25),

                            // --- Image Display and Upload Button ---
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                      height: 100,
                                      width: 100,
                                      margin:
                                          const EdgeInsets.only(bottom: 15.0),
                                      decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: _buildImagePreview())),
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.upload_file,
                                        color: darkContainerColor),
                                    label: const Text(
                                        'Uploader l\'image de l\'article',
                                        style: TextStyle(
                                            color: darkContainerColor)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: inputFillColor,
                                        foregroundColor: darkContainerColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 25, vertical: 12)),
                                  ),
                                  // Optional: Add button to clear picked image before saving
                                  if (_pickedImage != null)
                                    TextButton.icon(
                                      icon: const Icon(Icons.clear, size: 18),
                                      label: const Text('Effacer sélection'),
                                      onPressed: () => setState(() {
                                        _pickedImage = null;
                                        _webImageFuture = null;
                                      }),
                                    )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ), // End of dark container

                    const SizedBox(height: 30),

                    // --- Save Button ---
                    ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : _saveArticle, // Disable when submitting
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                          _isSubmitting ? 'Enregistrement...' : 'Sauvegarder',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3a3a3a),
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          elevation: 5),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
