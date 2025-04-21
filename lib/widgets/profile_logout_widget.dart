import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/auth_provider.dart';
import 'package:untitled/screens/login_page.dart';

class ProfileLogoutWidget extends StatelessWidget {
  const ProfileLogoutWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'logout') {
              // Show confirmation dialog
              final shouldLogout = await _showLogoutConfirmationDialog(context);

              if (shouldLogout && context.mounted) {
                // Perform logout
                await authProvider.logout();

                // Navigate to login screen
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false, // Clear the navigation stack
                  );
                }
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: const [
                  Icon(Icons.person, color: Color(0xFF5D9C88)),
                  SizedBox(width: 8),
                  Text('Profil'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Déconnexion'),
                ],
              ),
            ),
          ],
          icon: const Icon(
            Icons.account_circle,
            size: 30,
            color: Color(0xFF5D9C88),
          ),
        );
      },
    );
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
