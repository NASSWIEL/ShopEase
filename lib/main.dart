import 'package:flutter/material.dart';

import 'package:untitled/screens/gestion_article_vendeur_page.dart';
import 'package:untitled/screens/inscription_page.dart';
import 'package:untitled/screens/home_page.dart';
import 'package:untitled/screens/livraison_adresse_page.dart';
import 'package:untitled/screens/payment_page.dart';
import 'package:untitled/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'models/cart.dart';
import 'providers/auth_provider.dart'; // Import the auth provider
import 'utils/plugin_init.dart'; // Import the plugin initializer
import 'package:untitled/config/network_config.dart'; // Import network config

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized

  // Initialize plugins that need early initialization
  await PluginInitializer.initializePlugins();

  // Configure network settings for emulator/device
  NetworkConfig.configureForCurrentDevice();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Cart()),
        ChangeNotifierProvider(
            create: (ctx) => AuthProvider()), // Add auth provider
        // ...any other providers you might have
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for saved credentials and auto login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider
          .tryAutoLogin(); // This will attempt to log in with saved credentials
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShopEase',
      theme: ThemeData(primarySwatch: Colors.green),
      home:
          const SplashScreen(), // Changed to SplashScreen as the initial route
    );
  }
}
