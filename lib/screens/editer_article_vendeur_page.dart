import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/produit_vendeur.dart';
import '../services/api_service.dart'; // Import du service API

class EditerArticleVendeurPage extends StatefulWidget {
  final ProduitVendeur produit;

  const EditerArticleVendeurPage({super.key, required this.produit});

  @override
  _EditerArticleVendeurPageState createState() =>
      _EditerArticleVendeurPageState();
}

class _EditerArticleVendeurPageState extends State<EditerArticleVendeurPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  XFile? _newlyPickedImage; // Holds the NEW image picked by the user
  bool _imageDeleted =
      false; // Flag to track if current image was marked for deletion

  // API service
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the existing product data
    _barcodeController =
        TextEditingController(text: widget.produit.barcode ?? '');
    _nameController = TextEditingController(text: widget.produit.nom);
    _quantityController =
        TextEditingController(text: widget.produit.quantite.toString());
    _priceController = TextEditingController(
        text: widget.produit.prix.toStringAsFixed(2)); // Format price
    _descriptionController =
        TextEditingController(text: widget.produit.description ?? '');

    // Debug prints to diagnose the issue
    print('Product ID: ${widget.produit.id}');
    print('Product Name: ${widget.produit.nom}');
    print('Product Barcode: ${widget.produit.barcode}');
    print('Product Image URL: ${widget.produit.imageUrl}');
  }

  @override
  void dispose() {
    // Dispose controllers
    _barcodeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newlyPickedImage = pickedFile; // Store the newly picked file
          _imageDeleted =
              false; // If user picks new, don't consider old one deleted for UI
        });
        print('New image picked: ${pickedFile.path}');
      } else {
        print('No new image selected.');
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

  // --- Save Changes Logic ---
  Future<void> _saveChanges() async {
    // Validate form if needed
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Get values from controllers
    final updatedBarcode = _barcodeController.text;
    final updatedName = _nameController.text;

    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de l\'article est requis.')),
      );
      return;
    }

    final updatedQuantity = int.tryParse(_quantityController.text) ?? 0;
    final updatedPrice = double.tryParse(_priceController.text) ?? 0.0;
    final updatedDescription = _descriptionController.text;

    // Create updated product object
    final updatedProduit = widget.produit.copyWith(
      nom: updatedName,
      quantite: updatedQuantity,
      prix: updatedPrice,
      barcode: updatedBarcode.isEmpty ? null : updatedBarcode,
      description: updatedDescription.isEmpty ? null : updatedDescription,
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Get the ID as a string
      final String productId =
          widget.produit.idString ?? widget.produit.id.toString();
      print('Updating product with ID: $productId');

      // Call API to update product
      final ProduitVendeur updatedProduct = await _apiService.updateProduct(
        productId,
        updatedProduit,
        imageFile: _newlyPickedImage,
        deleteImage: _imageDeleted && _newlyPickedImage == null,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article modifié avec succès')),
        );

        // Return to previous screen with updated product
        Navigator.of(context).pop(updatedProduct);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $_errorMessage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color inputFillColor = Color(0xFFF5F5DC);
    const Color darkContainerColor = Color(0xFF424242);
    const Color labelColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5D9C88)),
          onPressed: () => Navigator.of(context)
              .pop(), // Pop without returning data (Cancel)
        ),
        centerTitle: true,
        title: SvgPicture.asset(
          'assets/images/logo.svg', // Ensure path is correct
          height: 55,
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5D9C88)),
                  SizedBox(height: 16),
                  Text("Mise à jour en cours..."),
                ],
              ),
            )
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
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: darkContainerColor,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Center(
                              child: Text(
                                'MODIFIER ARTICLE', // Title for editing
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // --- Input Fields (Initialized with data) ---
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
                                  hintText: 'Entrez le code-barre (optionnel)',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF5D9C88), width: 1.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12)),
                            ),
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
                                  hintText: 'Entrez le nom de l\'article',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF5D9C88), width: 1.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12)),
                            ),
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
                                  hintText: 'Entrez la quantité',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF5D9C88), width: 1.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12)),
                            ),
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
                                  hintText: 'Entrez le prix (ex: 12.99)',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF5D9C88), width: 1.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12)),
                            ),
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
                                      'Entrez une description (optionnel)',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF5D9C88), width: 1.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 12)),
                            ),
                            const SizedBox(height: 25),

                            // --- Image Display and Change/Delete Button ---
                            Center(
                              child: Column(
                                children: [
                                  // Display current or newly picked image preview
                                  Container(
                                    height: 100,
                                    width: 100,
                                    margin: const EdgeInsets.only(bottom: 15.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildImagePreview(),
                                    ),
                                  ),

                                  // Change Image Button
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.upload_file,
                                        color: darkContainerColor),
                                    label: const Text(
                                        'Changer l\'image de l\'article',
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

                                  // Delete Image Button (show only if there's an image to delete)
                                  if (_newlyPickedImage != null ||
                                      (!_imageDeleted &&
                                          widget.produit.imageUrl != null))
                                    TextButton.icon(
                                      icon: Icon(Icons.delete_outline,
                                          color: Colors.red[400]),
                                      label: Text('Supprimer l\'image',
                                          style: TextStyle(
                                              color: Colors.red[400])),
                                      onPressed: () {
                                        setState(() {
                                          _newlyPickedImage =
                                              null; // Clear any newly picked image
                                          _imageDeleted =
                                              true; // Mark current image for deletion on save
                                        });
                                      },
                                    ),
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
                          : _saveChanges, // Disable when submitting
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text(
                          _isSubmitting ? 'Mise à jour...' : 'Sauvegarder',
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

  // Helper method to build image preview
  Widget _buildImagePreview() {
    if (_newlyPickedImage != null) {
      // Show newly picked image
      if (kIsWeb) {
        // For web platform
        return FutureBuilder<Uint8List>(
          future: _newlyPickedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Icon(Icons.broken_image,
                  color: Colors.grey[600], size: 40);
            } else {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
          },
        );
      } else {
        // For mobile platforms
        return Image.file(
          File(_newlyPickedImage!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Error displaying file image: $error");
            return Icon(Icons.broken_image, color: Colors.grey[600], size: 40);
          },
        );
      }
    } else if (!_imageDeleted && widget.produit.imageUrl != null) {
      // Show existing image from URL - use the full URL from Cloudinary
      // This handles the correct URL format from your backend
      final url = widget.produit.imageUrl!;
      print("Displaying image from URL: $url");
      return Image.network(
        url,
        fit: BoxFit.cover,
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
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("Error loading image from URL: $error for URL: $url");
          return Icon(Icons.broken_image, color: Colors.grey[600], size: 40);
        },
      );
    } else {
      // No image or deleted image
      return Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40);
    }
  }
}
