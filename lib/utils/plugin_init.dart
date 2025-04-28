import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

/// Initializes plugins that require platform-specific initialization
class PluginInitializer {
  /// Initialize all necessary plugins
  static Future<void> initializePlugins() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Geolocator for web if needed
    if (kIsWeb) {
      try {
        await _initGeolocatorWeb();
      } catch (e) {
        print('Failed to initialize Geolocator for web: $e');
      }
    } else {
      // Request camera permission for barcode scanner
      await Permission.camera.request();
    }

    // Platform-specific initialization if needed
    try {
      // Initialize any plugins that need early setup
      // The barcode scanner will be initialized automatically by Flutter's plugin registry
    } catch (e) {
      print('Error initializing plugins: $e');
    }

    // Pre-load SharedPreferences instance
    await SharedPreferences.getInstance();

    // Here you can add initialization for other plugins if needed
  }

  /// Initialize Geolocator specifically for web platforms
  static Future<void> _initGeolocatorWeb() async {
    // This will initialize the web implementation
    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    ).catchError((e) {
      // Catch and handle the error, but don't re-throw it
      print('Initial position request error (expected): $e');
      return Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    });
  }
}
