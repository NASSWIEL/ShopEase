import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'inscription_page.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({Key? key}) : super(key: key);

  @override
  _ConnexionPageState createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // TODO: Implement login logic
    final username = _usernameController.text;
    final password = _passwordController.text;
    print('Username: $username, Password: $password');
  }

  void _navigateToInscription() {
    // Navigate to the inscription (sign-up) page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InscriptionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(
              maxWidth: 400,
              minHeight: 600, // Added minimum height
            ),
            padding: EdgeInsets.all(isSmallScreen ? 15.0 : 20.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSmallScreen ? 140 : 160, // Increased from 100/120
                  height: isSmallScreen ? 140 : 160, // Increased from 100/120
                  padding: const EdgeInsets.all(25), // Increased from 20
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D9C88),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      width: isSmallScreen ? 90 : 110, // Increased from 60/80
                      height: isSmallScreen ? 90 : 110, // Increased from 60/80
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Username Field
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Nom d'utilisateur",
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white12, // Slightly lighter field
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),

                // "Se connecter" Button
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C6149), // Darker green
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(color: Colors.white, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 20),

                // Registration Link
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Vous n'avez pas encore un compte?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _navigateToInscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(
                          color: Color(0xFF5D9C88),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: const Color(0xFF5D9C88),
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
