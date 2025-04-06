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

// Import the ProduitVendeur model (adjust path if needed)
import 'gestion_article_vendeur_page.dart' show ProduitVendeur;
// Import a package for generating unique IDs (optional but recommended)
// Add `uuid: ^4.3.3` (or latest) to your pubspec.yaml and run `flutter pub get`
// import 'package:uuid/uuid.dart';


class AjouterArticleVendeurPage extends StatefulWidget {
  const AjouterArticleVendeurPage({Key? key}) : super(key: key);

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

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Image Picking Logic (_pickImage remains the same) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
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


  // --- Save Article Logic (MODIFIED to return new product) ---
  Future<void> _saveArticle() async {
    // Optional: Validate form
    // if (!(_formKey.currentState?.validate() ?? false)) {
    //   return;
    // }

    String? finalImagePath; // The path to be saved (primarily for mobile)

    // 1. Copy the image if one was picked (Mobile Only for file saving)
    if (_pickedImage != null && !kIsWeb) {
      try {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final String originalFileName = p.basename(_pickedImage!.path);
        // Create a unique filename
        final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$originalFileName';
        final String destinationPath = p.join(appDocumentsDir.path, uniqueFileName);

        final File destinationFile = File(destinationPath);
        // Read bytes from XFile and write to the new file location
        await destinationFile.writeAsBytes(await _pickedImage!.readAsBytes());
        finalImagePath = destinationPath; // Store the path in app documents dir
        print('Image copied to (Mobile): $finalImagePath');

      } catch (e) {
        print('Error saving image (Mobile): $e');
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la sauvegarde de l\'image: $e')),
          );
        }
        return; // Stop saving if image copy failed
      }
    }
    // On Web, finalImagePath remains null if a new image was picked,
    // as we don't save a file path directly.

    // 2. Gather other form data
    final barcode = _barcodeController.text;
    final name = _nameController.text;
    // Add validation or default values if needed
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le nom de l\'article est requis.'))
      );
      return;
    }
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final description = _descriptionController.text;

    // 3. Create the new ProduitVendeur object
    // Generate a unique ID - using timestamp for simplicity here
    // For production, consider the 'uuid' package:
    // final String newId = Uuid().v4();
    final String newId = DateTime.now().toIso8601String();

    final ProduitVendeur newProduct = ProduitVendeur(
      id: newId, // Assign the generated unique ID
      nom: name,
      quantite: quantity,
      prix: price,
      barcode: barcode.isEmpty ? null : barcode,
      description: description.isEmpty ? null : description,
      imageUrl: finalImagePath, // This will be null on web if new image picked
    );


    // 4. Show feedback & Pop screen, returning the new product
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article ajouté (Simulation)')),
      );
      // Return the newly created product data to the previous screen
      Navigator.of(context).pop(newProduct); // <-- RETURN THE OBJECT
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
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            } else if (snapshot.hasError) {
              print("Error loading web image bytes: ${snapshot.error}");
              return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
            } else if (snapshot.hasData) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover, height: 100, width: 100);
            } else { return const Icon(Icons.image_not_supported, color: Colors.grey, size: 40); }
          },
        );
      } else {
        try { return Image.file(File(_pickedImage!.path), fit: BoxFit.cover, height: 100, width: 100, errorBuilder: (context, error, stackTrace) { print("Error displaying newly picked file image: $error"); return const Icon(Icons.broken_image, color: Colors.grey, size: 40); });
        } catch(e) { print("Error creating Image.file for picked image: $e"); return const Icon(Icons.error_outline, color: Colors.red, size: 40); }
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
      appBar: AppBar( /* ... AppBar code ... */
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF5D9C88)), onPressed: () => Navigator.of(context).pop()), // Just pop on back press
        centerTitle: true,
        title: SvgPicture.asset('assets/images/logo.svg', height: 55),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container( /* ... Main Dark Container ... */
                padding: const EdgeInsets.all(25.0),
                decoration: BoxDecoration(color: darkContainerColor, borderRadius: BorderRadius.circular(20.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))]),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Center(child: Text('AJOUTER UN ARTICLE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1), textAlign: TextAlign.center)),
                      const SizedBox(height: 30),

                      // --- Input Fields ---
                      // Code-barre
                      const Text('Code-barre:', style: TextStyle(color: labelColor)), const SizedBox(height: 5),
                      TextFormField(controller: _barcodeController, style: const TextStyle(color: Colors.black87), decoration: InputDecoration(filled: true, fillColor: inputFillColor, border: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none, ), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10))), const SizedBox(height: 15),
                      // Nom d'article (Required field check is in _saveArticle)
                      const Text('Nom d\'article:', style: TextStyle(color: labelColor)), const SizedBox(height: 5),
                      TextFormField(controller: _nameController, style: const TextStyle(color: Colors.black87), decoration: InputDecoration(filled: true, fillColor: inputFillColor, border: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0),  borderSide: BorderSide.none, ),  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10))), const SizedBox(height: 15),
                      // Quantité
                      const Text('Quantité:', style: TextStyle(color: labelColor)), const SizedBox(height: 5),
                      TextFormField(controller: _quantityController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(color: Colors.black87), decoration: InputDecoration(filled: true, fillColor: inputFillColor, border: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none, ), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10))), const SizedBox(height: 15),
                      // Prix unitaire
                      const Text('Prix unitaire:', style: TextStyle(color: labelColor)), const SizedBox(height: 5),
                      TextFormField(controller: _priceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], style: const TextStyle(color: Colors.black87), decoration: InputDecoration(filled: true, fillColor: inputFillColor, border: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none, ), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10))), const SizedBox(height: 15),
                      // Description
                      const Text('Description:', style: TextStyle(color: labelColor)), const SizedBox(height: 5),
                      TextFormField(controller: _descriptionController, maxLines: 4, style: const TextStyle(color: Colors.black87), decoration: InputDecoration(filled: true, fillColor: inputFillColor, border: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none, ), contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10))), const SizedBox(height: 25),


                      // --- Image Display and Upload Button ---
                      Center(
                        child: Column(
                          children: [
                            Container(
                                height: 100, width: 100, margin: const EdgeInsets.only(bottom: 15.0),
                                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                                child: ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildImagePreview())
                            ),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_file, color: darkContainerColor),
                              label: const Text('Uploader l\'image de l\'article', style: TextStyle(color: darkContainerColor)),
                              style: ElevatedButton.styleFrom(backgroundColor: inputFillColor, foregroundColor: darkContainerColor, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30.0), ), padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12)),
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
                onPressed: _saveArticle, // Calls the save function
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Sauvegarder', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3a3a3a), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(15.0), ), padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), elevation: 5),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}