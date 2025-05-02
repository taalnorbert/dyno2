import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class Signup extends StatefulWidget {
  // Change to StatefulWidget
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Add this variable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fekete háttér
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signin(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Tartalom középre igazítása
              children: [
                Text(
                  'Register Account',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: Colors.red, // Piros szöveg
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 40), // Kisebb távolság a cím és a mezők között
                _emailAddress(),
                const SizedBox(height: 20),
                _password(),
                const SizedBox(
                    height: 30), // Kisebb távolság a mezők és a gomb között
                _signup(context),
              ],
            ),
          ),
        ),
      ),
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

  Widget _signup(BuildContext context) {
    return Container(
      width: 300,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Sign Up button
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: GestureDetector(
              onTap: () async {
                await AuthService().signup(
                  email: _emailController.text,
                  password: _passwordController.text,
                  context: context,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: GestureDetector(
              onTap: () {
                context.go('/login');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    "Back",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        color: Colors.white,
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

  Widget _signin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "Already Have Account? ",
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Colors.grey, // Szürke szöveg
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            TextSpan(
              text: "Log In",
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Colors.red, // Piros szöveg
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.go('/login');
                },
            ),
          ],
        ),
      ),
    );
  }
}
