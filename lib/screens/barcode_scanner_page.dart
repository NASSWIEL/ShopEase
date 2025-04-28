import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool _hasNavigated = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de code-barres'),
        backgroundColor: const Color(0xFF2C6149),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: isFlashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
                controller.toggleTorch();
              });
            },
          ),
          IconButton(
            icon: Icon(
              isFrontCamera ? Icons.camera_front : Icons.camera_rear,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isFrontCamera = !isFrontCamera;
                controller.switchCamera();
              });
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && !_hasNavigated) {
            final String? barcode = barcodes.first.rawValue;
            if (barcode != null) {
              // Prevent multiple navigation attempts
              setState(() {
                _hasNavigated = true;
              });

              // Add a slight delay to ensure we don't have navigation conflicts
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  // Close the scanner and return the barcode
                  Navigator.of(context).pop(barcode);
                }
              });
            }
          }
        },
      ),
    );
  }
}
