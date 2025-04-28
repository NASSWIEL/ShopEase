import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  // Base URL for API requests - will select appropriate one based on platform
  static String get baseApiUrl {
    return "https://shopease-gkoz.onrender.com"; // Removed trailing slash
  }

  // Fallback URLs to try if the primary URL fails
  // On real Android devices, we should try IP addresses that might work
  static List<String> get fallbackUrls {
    if (Platform.isAndroid && !kIsWeb) {
      // Try different common network configurations
      return [
        'http://192.168.1.1:8000', // Common local IP
        'http://192.168.0.1:8000', // Alternative common local IP
        'http://localhost:8000', // Direct localhost (might work on some devices)
        'http://127.0.0.1:8000', // Alternative localhost
      ];
    }
    return []; // No fallbacks for other platforms
  }

  // Allow bypassing certificate verification for development
  static bool get allowInsecureConnections => true;

  // Connection timeout in seconds
  static int get connectionTimeout => 15; // Increased from default

  // Retry logic settings
  static int get maxRetries => 3;
  static int get retryDelayMillis => 1000;

  // API version
  static const String apiVersion = 'v1';

  // URL for static assets (like images)
  static String baseAssetUrl = 'http://10.0.2.2:8000';

  // Configure network settings based on the current device/platform
  static void configureForCurrentDevice() {
    // If running on Android emulator, use 10.0.2.2 (special IP that routes to host loopback)
    // If running on iOS simulator, use localhost
    // If running on physical device, you might need to use the actual IP of your computer on the network

    if (kIsWeb) {
      // For web, use relative URLs or the actual hosted backend URL
      baseAssetUrl = ''; // Empty for relative URLs
    } else if (Platform.isAndroid) {
      // Android emulator needs 10.0.2.2 to access host loopback
      baseAssetUrl = 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
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
