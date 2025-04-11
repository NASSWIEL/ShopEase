import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/screens/connexion_page.dart';
import 'package:untitled/screens/gestion_article_vendeur_page.dart';
import 'package:untitled/screens/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 5 seconds, checking for logged-in user
    Timer(const Duration(seconds: 5), () {
      _checkUserAndNavigate();
    });
  }

  Future<void> _checkUserAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser');
    final currentUserType = prefs.getString('currentUserType');

    if (currentUser != null && currentUserType != null) {
      // User is already logged in, navigate based on type
      if (currentUserType == 'vendeur') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const GestionArticleVendeurPage()),
          );
        }
      } else {
        // 'particulier' or any other user type
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } else {
      // No logged-in user, go to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConnexionPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.green, Colors.lightGreen],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.shopping_cart,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            // App name
            Text(
              'ShopEase',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 10),
            // Loading text in French
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
