import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:untitled/screens/gestion_article_vendeur_page.dart';
import 'package:untitled/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({Key? key}) : super(key: key);

  @override
  _InscriptionPageState createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _userType = 'particulier'; // Default user type
  bool _isLoading = false;

  // Sample predefined users (in a real app, this would be in a database)
  final Map<String, Map<String, String>> _predefinedUsers = {
    'vendeur1': {
      'password': 'vendeur123',
      'type': 'vendeur',
      'email': 'vendeur1@example.com'
    },
    'client1': {
      'password': 'client123',
      'type': 'particulier',
      'email': 'client1@example.com'
    },
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get user input
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final email = _emailController.text.trim();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if username already exists
      if (_predefinedUsers.containsKey(username)) {
        _showErrorDialog('Ce nom d\'utilisateur existe déjà.');
        return;
      }

      // In a real app, you would save this to a database
      // For this demo, we'll save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Save the new user
      await prefs.setString('user_$username', password);
      await prefs.setString('email_$username', email);
      await prefs.setString('type_$username', _userType);

      // Add to our in-memory map for this session
      _predefinedUsers[username] = {
        'password': password,
        'type': _userType,
        'email': email
      };

      // Store current user
      await prefs.setString('currentUser', username);
      await prefs.setString('currentUserType', _userType);

      // Navigate based on user type
      if (_userType == 'vendeur') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const GestionArticleVendeurPage()),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Une erreur est survenue: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Erreur d\'inscription'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
            constraints: const BoxConstraints(maxWidth: 400, minHeight: 600),
            padding: EdgeInsets.all(isSmallScreen ? 15.0 : 20.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isSmallScreen ? 140 : 160,
                    height: isSmallScreen ? 140 : 160,
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5D9C88),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: isSmallScreen ? 90 : 110,
                        height: isSmallScreen ? 90 : 110,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Inscription',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Nom d'utilisateur",
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom d\'utilisateur';
                      }
                      if (value.length < 4) {
                        return 'Le nom d\'utilisateur doit contenir au moins 4 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un email';
                      }
                      // Basic email validation
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // User Type Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Particulier',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          value: 'particulier',
                          groupValue: _userType,
                          onChanged: (value) {
                            setState(() {
                              _userType = value!;
                            });
                          },
                          activeColor: const Color(0xFF5D9C88),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Vendeur',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          value: 'vendeur',
                          groupValue: _userType,
                          onChanged: (value) {
                            setState(() {
                              _userType = value!;
                            });
                          },
                          activeColor: const Color(0xFF5D9C88),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF5D9C88))
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C6149),
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
                            "S'inscrire",
                            style: TextStyle(
                                color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // Login Link
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vous avez déjà un compte?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(
                            color: Color(0xFF5D9C88),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'Se connecter',
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
      ),
    );
  }
}
