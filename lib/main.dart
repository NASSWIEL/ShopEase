import 'package:flutter/material.dart';
import 'package:untitled/screens/connexion_page.dart';
import 'package:untitled/screens/inscription_page.dart';
import 'package:untitled/screens/home_page.dart';
import 'package:untitled/screens/splash_screen.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShopEase',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(), // Change this line
    );
  }
}
