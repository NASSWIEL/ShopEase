import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:untitled/screens/gestion_article_vendeur_page.dart';
import 'package:untitled/screens/home_page.dart';
import 'package:untitled/screens/inscription_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({Key? key}) : super(key: key);

  @override
  _ConnexionPageState createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = false;

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

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('savedUsername');

    if (savedUsername != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if user exists in predefined users first
      if (_predefinedUsers.containsKey(username) &&
          _predefinedUsers[username]!['password'] == password) {
        final userType = _predefinedUsers[username]!['type']!;

        // Save current user info to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUser', username);
        await prefs.setString('currentUserType', userType);

        // Save credentials if "remember me" is checked
        if (_rememberMe) {
          await prefs.setString('savedUsername', username);
        } else {
          await prefs.remove('savedUsername');
        }

        // Navigate based on user type
        if (userType == 'vendeur') {
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
        return;
      }

      // If not in predefined users, check SharedPreferences for registered users
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('user_$username');

      if (savedPassword != null && savedPassword == password) {
        final userType = prefs.getString('type_$username') ?? 'particulier';

        // Save current user
        await prefs.setString('currentUser', username);
        await prefs.setString('currentUserType', userType);

        // Save credentials if "remember me" is checked
        if (_rememberMe) {
          await prefs.setString('savedUsername', username);
        } else {
          await prefs.remove('savedUsername');
        }

        // Navigate based on user type
        if (userType == 'vendeur') {
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
      } else {
        _showErrorDialog('Nom d\'utilisateur ou mot de passe incorrect.');
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
          title: const Text('Erreur de connexion'),
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
            constraints: const BoxConstraints(maxWidth: 400, minHeight: 500),
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
                  // Logo Container
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

                  // Title
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
                  const SizedBox(height: 30),

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
                        return 'Veuillez entrer votre nom d\'utilisateur';
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
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Remember Me Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF5D9C88),
                      ),
                      const Text(
                        'Se souvenir de moi',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Implement forgot password functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Fonction à implémenter')),
                          );
                        },
                        child: const Text(
                          'Mot de passe oublié?',
                          style: TextStyle(color: Color(0xFF5D9C88)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF5D9C88))
                      : ElevatedButton(
                          onPressed: _login,
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
                            'Se connecter',
                            style: TextStyle(
                                color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // Register Link
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Vous n'avez pas de compte?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InscriptionPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(
                            color: Color(0xFF5D9C88),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: const Color(0xFF5D9C88),
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Sample User Info (for demo purposes)
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Utilisateurs de test:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text('Vendeur: vendeur1 / vendeur123',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Client: client1 / client123',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
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
