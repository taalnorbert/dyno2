import 'package:dyno2/services/auth_service.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/home.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:dyno2/speed_meter/widgets/Messages/warning_message.dart';

class Login extends StatefulWidget {
  // Change to StatefulWidget
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false; // Add this variable
  bool showLoginError = false;
  String errorMessage = '';

  // Add method to show warning
  void _showWarning(String message) {
    setState(() {
      errorMessage = message;
      showLoginError = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showLoginError = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userStream, // Felhasználói állapot figyelése
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Betöltés közben spinner
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          // Ha be van jelentkezve, navigálj a főoldalra
          return HomePage(); // Itt a SpeedMeter a főoldal
        } else {
          // Ha nincs bejelentkezve, jelenítsd meg a bejelentkezési képernyőt
          return Scaffold(
            backgroundColor: Colors.black, // Fekete háttér
            resizeToAvoidBottomInset: true,
            bottomNavigationBar: _signup(context),
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Tartalom középre igazítása
                        children: [
                          Text(
                            'Log in',
                            style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                color: Colors.red, // Piros szöveg
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ),
                          const SizedBox(
                              height:
                                  40), // Kisebb távolság a cím és a mezők között
                          _emailAddress(),
                          const SizedBox(height: 20),
                          _password(),
                          _forgotPassword(), // Add this line
                          const SizedBox(height: 20), // Reduced from 30 to 20
                          _combinedLoginButtons(context), // Kombinált gomb
                        ],
                      ),
                    ),
                  ),
                  if (showLoginError)
                    WarningMessage(
                      key: const Key('loginError'),
                      message: errorMessage,
                      icon: Icons.warning,
                      color: Colors.red,
                      iconColor: Colors.white,
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _emailAddress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.grey, // Szürke szöveg
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8), // Kisebb távolság a cím és a mező között
        SizedBox(
          width: 300, // Szélesség csökkentése
          child: TextField(
            controller: _emailController,
            style: const TextStyle(
                color: Colors.white), // Fehér szöveg a beviteli mezőben
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900], // Sötétszürke háttér
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: 'Enter your email', // Placeholder szöveg
              hintStyle:
                  const TextStyle(color: Colors.grey), // Szürke placeholder
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16), // Kisebb padding
            ),
          ),
        ),
      ],
    );
  }

  Widget _password() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.grey, // Szürke szöveg
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8), // Kisebb távolság a cím és a mező között
        SizedBox(
          width: 300, // Szélesség csökkentése
          child: TextField(
            obscureText: !_isPasswordVisible, // Toggle visibility
            controller: _passwordController,
            style: const TextStyle(
                color: Colors.white), // Fehér szöveg a beviteli mezőben
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900], // Sötétszürke háttér
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: 'Enter your password', // Placeholder szöveg
              hintStyle:
                  const TextStyle(color: Colors.grey), // Szürke placeholder
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16), // Kisebb padding
              suffixIcon: IconButton(
                // Add eye icon
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _combinedLoginButtons(BuildContext context) {
    return Container(
      width: 300,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: GestureDetector(
              onTap: () async {
                _handleLogin();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red, // Piros háttér
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Sign In",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        color: Colors.white, // Fehér szöveg
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Jobb oldali rész: Guest
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 150, // A jobb oldali rész szélessége
            child: GestureDetector(
              onTap: () {
                context.go('/home');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800], // Szürke háttér
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Guest",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        color: Colors.white, // Fehér szöveg
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "New User? ",
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Colors.grey, // Szürke szöveg
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            TextSpan(
              text: "Create Account",
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Colors.red, // Piros szöveg
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.go('/signup');
                },
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to _LoginState class
  Widget _forgotPassword() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 24),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                final emailController = TextEditingController();
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Reset Password',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter your email address to reset your password',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        _authService.resetPassword(
                          email: emailController.text,
                          context: context,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.raleway(
              textStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Update login button handler
  void _handleLogin() async {
    try {
      await AuthService().signin(
        email: _emailController.text,
        password: _passwordController.text,
        context: context,
      );
    } catch (e) {
      _showWarning(e.toString());
    }
  }
}
