import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shopease/screens/payment_page.dart';

class LivraisonAdressePage extends StatefulWidget {
  final double cartTotal;

  const LivraisonAdressePage({
    super.key,
    required this.cartTotal, // Make it required to ensure a value is always provided
  });

  @override
  State<LivraisonAdressePage> createState() => _LivraisonAdressePageState();
}

class _LivraisonAdressePageState extends State<LivraisonAdressePage> {
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _currentLocation = LatLng(48.8566, 2.3522); // Default to Paris
  String _currentAddress = '';
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _updateMarker();
    print("LivraisonAdressePage received cart total: ${widget.cartTotal}");
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _updateMarker();
      _getAddressFromLatLng();
      _mapController.move(_currentLocation, 15.0);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = [
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentLocation,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
        ),
      ];
    });
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
          // Update the text field without triggering suggestions
          _addressController.text = _currentAddress;

          // Clear any active suggestions
          FocusManager.instance.primaryFocus?.unfocus();
        });
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  Future<void> _getLocationFromAddress(String address) async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(
        address,
      );

      if (locations.isNotEmpty) {
        setState(() {
          _currentLocation = LatLng(
            locations[0].latitude,
            locations[0].longitude,
          );
        });

        _updateMarker();
        _mapController.move(_currentLocation, 15.0);
      }
    } catch (e) {
      print("Error getting location from address: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't find that address. Please try again."),
          ),
        );
      }
    }
  }

  Future<List<String>> _getSuggestions(String query) async {
    if (query.length < 3) return [];

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((place) => place['display_name'].toString()).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TypeAheadField<String>(
              controller: _addressController,
              // Add key to force rebuild when map location changes
              key: ValueKey(_currentLocation.toString()),
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Saisissez votre adresse',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
              decorationBuilder: (context, child) {
                return Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(10.0),
                  color: Theme.of(context).cardColor,
                  child: child,
                );
              },
              suggestionsCallback: (query) async {
                final suggestions = await _getSuggestions(query);
                return suggestions.take(3).toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(suggestion),
                );
              },
              onSelected: (suggestion) {
                _addressController.text = suggestion;
                _getLocationFromAddress(suggestion);
              },
              debounceDuration: const Duration(milliseconds: 500),
              hideOnSelect: true,
              hideOnUnfocus: false,

              hideOnEmpty: true,
              hideOnLoading: true,
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 30.0,
                onTap: (_, latLng) {
                  setState(() {
                    _currentLocation = latLng;
                  });
                  _updateMarker();
                  _getAddressFromLatLng();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),

          // Show the cart total
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text(
                  'Montant du panier:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${widget.cartTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_currentAddress.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez sélectionner une adresse')),
                  );
                  return;
                }

                // Debug print
                print("Passing cart total to PaymentPage: ${widget.cartTotal}");

                // Navigate to payment page with address and cart total
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(
                      deliveryAddress: _currentAddress,
                      cartTotal: widget.cartTotal,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF5D9C88),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Continuer vers le paiement',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
