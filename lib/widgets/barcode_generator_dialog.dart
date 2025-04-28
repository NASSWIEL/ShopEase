import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/barcode_service.dart';

class BarcodeGeneratorDialog extends StatefulWidget {
  final String? initialBarcode;
  final Function(String) onBarcodeGenerated;

  const BarcodeGeneratorDialog({
    Key? key,
    this.initialBarcode,
    required this.onBarcodeGenerated,
  }) : super(key: key);

  @override
  _BarcodeGeneratorDialogState createState() => _BarcodeGeneratorDialogState();
}

class _BarcodeGeneratorDialogState extends State<BarcodeGeneratorDialog> {
  late TextEditingController _barcodeController;
  late BarcodeType _selectedBarcodeType;
  String? _validationMessage;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _barcodeController =
        TextEditingController(text: widget.initialBarcode ?? '');
    _selectedBarcodeType = BarcodeType.; // This needs to be changed to a valid constant
    // You might need to replace it with one of these: BarcodeType.ean8, BarcodeType.ean13
    // or BarcodeType.code128, depending on what's defined in your BarcodeType enum
    _validateBarcode(_barcodeController.text);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _validateBarcode(String value) {
    setState(() {
      if (value.isEmpty) {
        _validationMessage = 'Veuillez saisir un code-barres';
        _isValid = false;
      } else {
        _isValid = BarcodeService.isValidData(value, _selectedBarcodeType);
        _validationMessage = _isValid
            ? null
            : BarcodeService.getValidationMessage(_selectedBarcodeType);
      }
    });
  }

  void _onBarcodeTypeChanged(BarcodeType? newType) {
    if (newType != null) {
      setState(() {
        _selectedBarcodeType = newType;
        _validateBarcode(_barcodeController.text);
      });
    }
  }

  void _generateSampleBarcode() {
    setState(() {
      _barcodeController.text =
          BarcodeService.getSampleData(_selectedBarcodeType);
      _validateBarcode(_barcodeController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 5,
      backgroundColor: Colors.grey[200],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Générer un Code-Barres',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D9C88),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<BarcodeType>(
                value: _selectedBarcodeType,
                decoration: InputDecoration(
                  labelText: 'Type de Code-Barres',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: BarcodeType.values.map((BarcodeType type) {
                  return DropdownMenuItem<BarcodeType>(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: _onBarcodeTypeChanged,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Données du Code-Barres',
                  helperText: _validationMessage,
                  helperStyle: TextStyle(
                    color: _validationMessage != null && !_isValid
                        ? Colors.red
                        : Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Générer un exemple',
                    onPressed: _generateSampleBarcode,
                  ),
                ),
                onChanged: _validateBarcode,
              ),
              const SizedBox(height: 20),
              if (_isValid)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: BarcodeService.buildBarcodeWidget(
                    data: _barcodeController.text,
                    type: _selectedBarcodeType,
                    width: 280,
                    height: _selectedBarcodeType == BarcodeType.qrCode ||
                            _selectedBarcodeType == BarcodeType.dataMatrix
                        ? 150
                        : 100,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: _isValid
                        ? () {
                            widget.onBarcodeGenerated(_barcodeController.text);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D9C88),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Utiliser ce Code'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isValid)
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier le code'),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: _barcodeController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copié dans le presse-papier'),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
