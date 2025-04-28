import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopease/config/network_config.dart';

/// A utility class to help configure the server IP address
/// especially when using a physical device to connect to a development server
class ServerConfigUtil {
  // Key for storing server IP in SharedPreferences
  static const String _serverIpKey = 'server_ip_address';

  /// Get the stored server IP address, or default if not set
  static Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIp = prefs.getString(_serverIpKey);

    // Use stored IP if available, otherwise use default
    if (storedIp != null && storedIp.isNotEmpty) {
      return storedIp;
    }

    return _getDefaultServerIp();
  }

  /// Save a custom server IP address
  static Future<void> saveServerIp(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverIpKey, ipAddress);

    // Update the NetworkConfig with the new IP
    _updateNetworkConfig(ipAddress);
  }

  /// Reset to the default server IP
  static Future<void> resetServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverIpKey);

    final defaultIp = _getDefaultServerIp();
    _updateNetworkConfig(defaultIp);
  }

  /// Get the default server IP based on platform
  static String _getDefaultServerIp() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  /// Update NetworkConfig with the new IP
  static void _updateNetworkConfig(String serverIp) {
    NetworkConfig.baseAssetUrl = serverIp;
    // Note: We can't update baseApiUrl directly since it's a getter,
    // but we can use the provided IP in our API calls
  }

  /// Show a dialog to configure the server IP
  static Future<void> showServerConfigDialog(BuildContext context) async {
    final currentIp = await getServerIp();
    final controller = TextEditingController(text: currentIp);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Server Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your development server IP address and port.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
                'If using a physical device, enter your computer\'s IP address on the same network.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server Address',
                hintText: 'http://192.168.1.100:8000',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await resetServerIp();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Reset to Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIp = controller.text.trim();
              if (newIp.isNotEmpty) {
                await saveServerIp(newIp);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
