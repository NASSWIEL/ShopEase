import 'package:flutter/material.dart';
import 'package:untitled/screens/connexion_page.dart';
import 'package:untitled/screens/gestion_article_vendeur_page.dart';
import 'package:untitled/screens/inscription_page.dart';
import 'package:untitled/screens/home_page.dart';
import 'package:untitled/screens/livraison_adresse_page.dart';
import 'package:untitled/screens/payment_page.dart';
import 'package:untitled/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'models/cart.dart';
import 'utils/plugin_init.dart'; // Import the plugin initializer

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized

  // Initialize plugins that need early initialization
  await PluginInitializer.initializePlugins();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Cart()),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShopEase',
      theme: ThemeData(primarySwatch: Colors.green),
      home:
          const SplashScreen(), // Changed to SplashScreen as the initial route
    );
  }
}
