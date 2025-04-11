import 'package:flutter/material.dart';

/// A simplified barcode scanner service that uses simulation
/// to avoid native plugin issues
class BarcodeScannerService {
  /// Simulates a barcode scan with common product codes
  static Future<String> scanBarcode(BuildContext context) async {
    // Show a dialog with barcode options for simulation
    return simulateScan(context);
  }

  /// Simulates a barcode scan with predefined options
  static Future<String> simulateScan(BuildContext context) async {
    final List<Map<String, String>> demoProducts = [
      {'barcode': '123456789', 'name': 'Nike Air Max'},
      {'barcode': '987654321', 'name': 'Adidas Ultraboost'},
      {'barcode': '456789123', 'name': 'Puma Running Shoes'},
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Simulation de scan de code-barres'),
          children: [
            ...demoProducts.map((product) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, product['barcode']);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.barcode_reader),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['name']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('Code: ${product['barcode']}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, '-1');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Annuler', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? '-1';
  }

  /// Gets product information based on barcode
  static Map<String, String>? getProductInfo(String barcode) {
    // Sample product database
    final Map<String, Map<String, String>> productDatabase = {
      '123456789': {
        'name': 'Nike Air Max',
        'price': '129.99',
        'description':
            'Chaussures de sport avec une excellente absorption des chocs.'
      },
      '987654321': {
        'name': 'Adidas Ultraboost',
        'price': '159.99',
        'description':
            'Chaussures de course confortables avec technologie Boost.'
      },
      '456789123': {
        'name': 'Puma Running Shoes',
        'price': '89.99',
        'description': 'Chaussures légères pour la course quotidienne.'
      }
    };

    return productDatabase[barcode];
  }
}
