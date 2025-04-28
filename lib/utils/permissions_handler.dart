import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  /// Request microphone permission for speech recognition
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      print("Checking microphone permission status");
      PermissionStatus status = await Permission.microphone.status;
      print("Current microphone permission status: $status");

      if (status.isGranted) {
        print("Microphone permission already granted");
        return true;
      }

      if (status.isDenied) {
        print("Requesting microphone permission");
        status = await Permission.microphone.request();
        print("Permission request result: $status");
        return status.isGranted;
      }

      if (status.isPermanentlyDenied) {
        print("Microphone permission permanently denied");
        _showPermissionDialog(context);
        return false;
      }

      if (status.isRestricted || status.isLimited) {
        print("Microphone permission is restricted or limited");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone access is restricted on this device')),
        );
        return false;
      }

      return false;
    } catch (e) {
      print("Error requesting microphone permission: $e");
      return false;
    }
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
            'This app needs microphone access for speech recognition. '
            'Please enable it in your device settings.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }
}
