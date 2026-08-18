import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';

// Login screen - needs to be Stateful because it manages local,
// temporary UI state (text field contents, password visibility)
// that AuthProvider doesn't need to know about.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers act like a "notepad" clipped to each text field -
  // they silently record what the user types so we can read it later.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Tracks whether the password is currently hidden (dots) or visible.
  // Purely cosmetic - doesn't need to be 'final' since it toggles.
  bool _obscurePassword = true;

  // Called automatically when this screen is removed from the widget tree.
  // Controllers hold onto memory behind the scenes, so we must manually
  // release them here to avoid memory leaks.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Builds the actual UI. Runs every time setState() is called.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dark background matching the Stitch design
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        // SafeArea keeps content clear of notches/status bars/home indicator
        child: Center(
          child: SingleChildScrollView(
            // Scrollable so the keyboard popping up doesn't cause an overflow error
            padding: const EdgeInsets.all(24),
            child: Container(
              // The white "card" that holds the whole login form
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                // min = card hugs its content height instead of stretching
                // stretch = children fill the card's width
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App title
                  const Text(
                    'ChapaChap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB8342A), // brand red from the design
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle/tagline
                  const Text(
                    'Effortless cravings delivered fast.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color.fromARGB(255, 103, 101, 101)),
                  ),
                  const SizedBox(height: 24),
                  // --- Email field ---
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller:
                        _emailController, // reads/writes into our "notepad"
                    keyboardType:
                        TextInputType.emailAddress, // shows @ on keyboard
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide
                            .none, // no visible outline, just the fill
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Password field, with "Forgot?" link above it ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: wire up forgot-password flow later (not in current scope)
                        },
                        child: const Text(
                          'Forgot?',
                          style: TextStyle(color: Color(0xFFB8342A)),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // hides text when true
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      // Eye icon toggles _obscurePassword when tapped
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          // setState tells Flutter "redraw this screen, something changed"
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Log In button ---
                  // context.watch<AuthProvider>() rebuilds this widget whenever
                  // AuthProvider calls notifyListeners() - e.g. isLoading flips,
                  // or an error message appears. That's how the button knows
                  // to show a spinner / disable itself / display an error.
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Show an error message if login failed
                          if (authProvider.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                authProvider.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB8342A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            // Disable the button while a login request is in flight,
                            // so the user can't spam-tap it and fire duplicate requests.
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                                    final success = await authProvider.login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    // pushReplacement: user shouldn't be able to
                                    // hit "back" from Home and land on Login again
                                    if (success && context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HomeScreen(),
                                        ),
                                      );
                                    }
                                    // 'mounted' check: makes sure this screen is still
                                    // on-screen before we try to navigate - avoids a
                                    // crash if the user backed out mid-request.
                                    if (context.mounted) {
                                      // TEMPORARY debug feedback - remove once
                                      // real navigation to Home screen exists
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Login succeeded! User: ${authProvider.currentUser?.email}'
                                                : 'Login failed (see error above)',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Log In →'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // --- "OR CONTINUE WITH" divider ---
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Google button (visual placeholder - not wired to real OAuth yet) ---
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: implement Google Sign-In - not in current backend scope
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Log in with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- Apple button (visual placeholder - not wired to real OAuth yet) ---
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: implement Apple Sign-In - not in current backend scope
                    },
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Sign in with Apple'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Footer: switch to Register screen ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Color(0xFFB8342A),
                            fontWeight: FontWeight.bold,
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
