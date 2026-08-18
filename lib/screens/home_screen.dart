import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

// Minimal placeholder Home screen. Real content (restaurant browsing,
// menus, etc.) comes later once Stitch designs for those screens exist.
// For now, this exists to prove the auth flow is fully closed-loop:
// login/register successfully lands here, and logout correctly exits.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch() here (not read()) because we want this screen to rebuild
    // if the user's info ever changes while they're on this screen.
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('ChapaChap'),
        backgroundColor: const Color(0xFFB8342A),
        actions: [
          // Logout button in the top-right corner
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              // pushReplacement so the user can't hit "back" and
              // return to a Home screen they're no longer logged into
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.name ?? 'User'}!',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}