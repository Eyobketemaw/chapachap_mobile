import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// The "bouncer at the door" - decides what the user sees when the app
// first launches, based on whether a valid saved session exists.
// Needs to be Stateful because it triggers tryAutoLogin() exactly once,
// when this widget is first created.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Tracks whether we've finished checking for a saved session yet.
  // Starts false - we don't know the answer until tryAutoLogin() completes.
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    // initState runs once, right when this widget is first created -
    // the perfect place to kick off a one-time startup check.
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // context.read (not watch) - we only need AuthProvider once here,
    // to call a method on it, not to rebuild this function.
    await context.read<AuthProvider>().tryAutoLogin();

    // mounted check: this screen might be gone by the time the async
    // call finishes (unlikely here, but it's the same safety habit
    // we used in Login/Register - always check before touching state).
    if (mounted) {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still checking - show a simple loading screen (the "holding area")
    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB8342A)),
        ),
      );
    }

    // Check finished - watch() here so if the user logs out later,
    // this widget could react (not strictly needed today, but correct
    // going forward as the app grows).
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}