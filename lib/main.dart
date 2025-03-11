import 'package:flutter/material.dart';
import 'package:untitled/screens/inscription_page.dart'; // Make sure this file exists in your project
import 'package:untitled/screens/home_page.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),  // Ensure HomePage() is set here
    );
  }
}
