import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  // Base API URL that will be configured based on environment
  static String baseApiUrl = 'http://10.0.2.2:8000';

  // URL for static assets (like images)
  static String baseAssetUrl = 'http://10.0.2.2:8000';

  // Fallback URLs to try if the main URL fails
  static final List<String> fallbackUrls = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
  ];

  // Flag to allow insecure connections for development
  static bool allowInsecureConnections = true;

  // Connection timeout in seconds
  static int connectionTimeout = 10;

  // Configure network settings based on the current device/platform
  static void configureForCurrentDevice() {
    // If running on Android emulator, use 10.0.2.2 (special IP that routes to host loopback)
    // If running on iOS simulator, use localhost
    // If running on physical device, you might need to use the actual IP of your computer on the network

    if (kIsWeb) {
      // For web, use relative URLs or the actual hosted backend URL
      baseApiUrl = '/api'; // Use relative URL for web
      baseAssetUrl = ''; // Empty for relative URLs
      allowInsecureConnections = false;
    } else if (Platform.isAndroid) {
      // Android emulator needs 10.0.2.2 to access host loopback
      baseApiUrl = 'http://10.0.2.2:8000';
      baseAssetUrl = 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      baseApiUrl = 'http://localhost:8000';
      baseAssetUrl = 'http://localhost:8000';
    }

    // Debug: Print the configured URLs
    print('NetworkConfig: Base API URL set to $baseApiUrl');
    print('NetworkConfig: Base Asset URL set to $baseAssetUrl');
  }

  // Helper method to convert relative paths to absolute URLs for images
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // If the URL is already absolute (contains http:// or https://), return as is
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }

    // If it's a relative path, join it with the base asset URL
    // Make sure the path doesn't start with '/' if baseAssetUrl ends with '/'
    if (baseAssetUrl.endsWith('/') && relativePath.startsWith('/')) {
      return baseAssetUrl + relativePath.substring(1);
    }

    if (!baseAssetUrl.endsWith('/') && !relativePath.startsWith('/')) {
      return baseAssetUrl + '/' + relativePath;
    }

    return baseAssetUrl + relativePath;
  }
}
