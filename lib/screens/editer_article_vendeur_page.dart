import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/produit_vendeur.dart'; // Import the model

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
  String? _currentImagePath; // Holds the path of the EXISTING image
  bool _imageDeleted =
      false; // Flag to track if current image was marked for deletion

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
    _currentImagePath = widget.produit.imageUrl; // Store existing image path
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

  // --- Delete existing image file (Utility) ---
  Future<void> _deleteFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Deleted old image file: $filePath');
      }
    } catch (e) {
      print('Error deleting file $filePath: $e');
      // Log or handle silently
    }
  }

  // --- Save Changes Logic ---
  Future<void> _saveChanges() async {
    String? finalImagePath = _currentImagePath; // Start with the current path
    bool deletingOld = false; // Track if we need to delete the old file

    // 1. Handle image change: Copy new image OR handle deletion
    if (_newlyPickedImage != null) {
      // User picked a NEW image
      try {
        final Directory appDocumentsDir =
            await getApplicationDocumentsDirectory();
        final String originalFileName = p.basename(_newlyPickedImage!.path);
        final String uniqueFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
        final String destinationPath =
            p.join(appDocumentsDir.path, uniqueFileName);

        final File destinationFile = File(destinationPath);
        await destinationFile
            .writeAsBytes(await _newlyPickedImage!.readAsBytes());

        // Mark old image for deletion IF it exists
        deletingOld =
            _currentImagePath != null && _currentImagePath!.isNotEmpty;
        finalImagePath = destinationPath; // Update to the new image path
        print('New image copied to: $finalImagePath');
      } catch (e) {
        print('Error saving new image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur sauvegarde nouvelle image: $e')),
          );
        }
        return; // Stop saving if image copy failed
      }
    } else if (_imageDeleted) {
      // User explicitly deleted the image without picking new
      deletingOld = true;
      finalImagePath = null; // Set path to null as image is removed
      print('Image marked for deletion, final path set to null.');
    }

    // 2. Delete the old file AFTER processing new/deleted state
    if (deletingOld) {
      await _deleteFile(_currentImagePath);
    }

    // 3. Gather updated data from controllers
    final updatedBarcode = _barcodeController.text;
    final updatedName = _nameController.text;
    final updatedQuantity = int.tryParse(_quantityController.text) ??
        widget.produit.quantite; // Fallback
    final updatedPrice = double.tryParse(_priceController.text) ??
        widget.produit.prix; // Fallback
    final updatedDescription = _descriptionController.text;

    // 4. Create the updated ProduitVendeur object using copyWith
    final updatedProduit = widget.produit.copyWith(
      nom: updatedName,
      quantite: updatedQuantity,
      prix: updatedPrice,
      barcode:
          updatedBarcode.isEmpty ? null : updatedBarcode, // Handle empty string
      description: updatedDescription.isEmpty
          ? null
          : updatedDescription, // Handle empty string
      // Use ValueGetter to explicitly pass null if image was deleted
      imageUrlFn: () => finalImagePath,
    );

    // 5. Show feedback & Pop screen, returning the updated product
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifications sauvegardées')),
      );
      // Return the updated product data to the previous screen
      Navigator.of(context).pop(updatedProduit);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color inputFillColor = Color(0xFFF5F5DC);
    const Color darkContainerColor = Color(0xFF424242);
    const Color labelColor = Colors.white;

    // Determine which image to display
    ImageProvider? displayImageProvider;
    String? imagePathToShow =
        _newlyPickedImage?.path ?? (!_imageDeleted ? _currentImagePath : null);

    if (imagePathToShow != null && imagePathToShow.isNotEmpty) {
      try {
        // Check existence for FileImage to prevent crash if file deleted externally
        if (File(imagePathToShow).existsSync()) {
          displayImageProvider = FileImage(File(imagePathToShow));
        } else {
          print(
              "Warning: Image path exists but file not found: $imagePathToShow");
          // Reset image state if file doesn't exist
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                if (_newlyPickedImage?.path == imagePathToShow)
                  _newlyPickedImage = null;
                if (_currentImagePath == imagePathToShow)
                  _currentImagePath = null;
                _imageDeleted = false; // Ensure flag is reset
              });
            }
          });
        }
      } catch (e) {
        // Catch potential errors from File operations
        print("Error creating FileImage: $e");
      }
    }

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
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
                          'DÉTAILLE ARTICLE', // Title for editing
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10)),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10)),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10)),
                      ),
                      const SizedBox(height: 15),

                      // Prix unitaire
                      const Text('Prix unitaire:',
                          style: TextStyle(color: labelColor)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: inputFillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10)),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10)),
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
                                color: Colors.grey[300], // Placeholder color
                                borderRadius: BorderRadius.circular(10),
                                image: displayImageProvider != null
                                    ? DecorationImage(
                                        image: displayImageProvider,
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                          print(
                                              "Error loading image preview: $exception");
                                        })
                                    : null,
                              ),
                              child: displayImageProvider == null
                                  ? Icon(Icons.image_not_supported,
                                      color: Colors.grey[600], size: 40)
                                  : null,
                            ),

                            // Change Image Button
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_file,
                                  color: darkContainerColor),
                              label: const Text(
                                  'Changer l\'image de l\'article',
                                  style: TextStyle(color: darkContainerColor)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: inputFillColor,
                                  foregroundColor: darkContainerColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 25, vertical: 12)),
                            ),
                            // Optional: Add a button to explicitly remove the image
                            if (imagePathToShow !=
                                null) // Show delete only if there is an image
                              TextButton.icon(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red[400]),
                                label: Text('Supprimer l\'image',
                                    style: TextStyle(color: Colors.red[400])),
                                onPressed: () {
                                  setState(() {
                                    _newlyPickedImage =
                                        null; // Clear any newly picked image
                                    _imageDeleted =
                                        true; // Mark current image for deletion on save
                                  });
                                  print("Image marked for deletion.");
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
                onPressed: _saveChanges, // Call the save changes function
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Sauvegarder',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3a3a3a),
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
