import 'package:flutter/material.dart';

// Update imports to use the correct package name
import 'package:shopease/screens/gestion_article_vendeur_page.dart';
import 'package:shopease/screens/inscription_page.dart';
import 'package:shopease/screens/home_page.dart';
import 'package:shopease/screens/livraison_adresse_page.dart';
import 'package:shopease/screens/payment_page.dart';
import 'package:shopease/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'models/cart.dart';
import 'providers/auth_provider.dart';
import 'utils/plugin_init.dart';
import 'package:shopease/config/network_config.dart';
import 'package:shopease/utils/server_config_util.dart'; // Import server config utility
import 'package:shopease/screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized

  // Initialize plugins that need early initialization
  await PluginInitializer.initializePlugins();

  // Load custom server IP if configured
  final customIp = await ServerConfigUtil.getServerIp();
  NetworkConfig.baseAssetUrl =
      "https://shopease-gkoz.onrender.com"; // Removed trailing slash
  print('Using server address: $customIp');

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
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF5D9C88),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF5D9C88),
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginPage(),
    );
  }
}
