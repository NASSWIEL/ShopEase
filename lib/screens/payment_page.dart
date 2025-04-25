import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:untitled/screens/home_page.dart';

class PaymentPage extends StatefulWidget {
  final String deliveryAddress;
  final double cartTotal;

  const PaymentPage(
      {Key? key, required this.deliveryAddress, required this.cartTotal})
      : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  late double _cartTotal;

  // Controllers for the text fields
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderNameController =
      TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Card type (Visa, Mastercard, etc.)
  String _cardType = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cartTotal = widget.cartTotal;
    print("PaymentPage received cart total: $_cartTotal");

    // Validate cart total - should never be 0
    if (_cartTotal <= 0) {
      print("WARNING: Invalid cart total received: $_cartTotal");
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Detect card type based on the first few digits
  void _detectCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) {
      setState(() => _cardType = 'Visa');
    } else if (cardNumber.startsWith('5')) {
      setState(() => _cardType = 'MasterCard');
    } else if (cardNumber.startsWith('3')) {
      setState(() => _cardType = 'American Express');
    } else if (cardNumber.startsWith('6')) {
      setState(() => _cardType = 'Discover');
    } else {
      setState(() => _cardType = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: const Color(0xFF5D9C88),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de la commande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D9C88),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delivery Address
                  const Text(
                    'Adresse de livraison:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.deliveryAddress),
                  const Divider(height: 24),

                  // Cart Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Montant du panier:'),
                      Text('${_cartTotal.toStringAsFixed(2)} €'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Shipping Cost
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Frais de livraison:'),
                      Text('5.99 €'),
                    ],
                  ),
                  const Divider(height: 16),

                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${(_cartTotal + 5.99).toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF5D9C88),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Section
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détails de paiement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D9C88),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Credit card preview
                  Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D9C88),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 50,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.credit_card_rounded,
                                    color: Colors.white),
                              ),
                            ),
                            Text(
                              _cardType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _cardNumberController.text.isEmpty
                              ? 'XXXX XXXX XXXX XXXX'
                              : _cardNumberController.text.replaceAllMapped(
                                  RegExp(r".{4}"),
                                  (match) => "${match.group(0)} ",
                                ),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TITULAIRE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _cardHolderNameController.text.isEmpty
                                      ? 'VOTRE NOM'
                                      : _cardHolderNameController.text
                                          .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'EXPIRE',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _expiryDateController.text.isEmpty
                                      ? 'MM/AA'
                                      : _expiryDateController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Card Number
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de carte',
                      hintText: '1234 5678 9012 3456',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    onChanged: (value) {
                      setState(() {});
                      if (value.isNotEmpty) {
                        _detectCardType(value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro de carte';
                      }
                      if (value.length < 16) {
                        return 'Numéro de carte invalide';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Card Holder Name
                  TextFormField(
                    controller: _cardHolderNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du titulaire',
                      hintText: 'Jean Dupont',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le nom du titulaire';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Expiry Date and CVV in a Row
                  Row(
                    children: [
                      // Expiry Date
                      Expanded(
                        child: TextFormField(
                          controller: _expiryDateController,
                          decoration: InputDecoration(
                            labelText: 'Date d\'expiration',
                            hintText: 'MM/YY',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryDateInputFormatter(),
                          ],
                          onChanged: (value) {
                            setState(() {});
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            if (value.length < 5) {
                              return 'Date invalide';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      // CVV
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                            prefixIcon: const Icon(Icons.security),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            if (value.length < 3) {
                              return 'CVV invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isProcessing = true;
                                });

                                // Show processing message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Traitement du paiement en cours...'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );

                                // Simulate payment processing
                                await Future.delayed(
                                    const Duration(seconds: 2));

                                // Show success message and navigate to home
                                if (context.mounted) {
                                  // Show success dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Paiement réussi'),
                                        content: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 60,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                                'Votre commande a été confirmée et sera livrée à l\'adresse indiquée.'),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              // Navigate to home and clear all previous routes
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const HomePage()),
                                                (route) => false,
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D9C88),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Payer maintenant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    StringBuffer newText = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2 && text.length > 2 && !text.contains('/')) {
        newText.write('/');
      }
      newText.write(text[i]);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
