import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class Signup extends StatelessWidget {
  Signup({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
              mainAxisAlignment: MainAxisAlignment.center, // Tartalom középre igazítása
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
                const SizedBox(height: 40), // Kisebb távolság a cím és a mezők között
                _emailAddress(),
                const SizedBox(height: 20),
                _password(),
                const SizedBox(height: 30), // Kisebb távolság a mezők és a gomb között
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
            style: const TextStyle(color: Colors.white), // Fehér szöveg a beviteli mezőben
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900], // Sötétszürke háttér
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: 'Enter your email', // Placeholder szöveg
              hintStyle: const TextStyle(color: Colors.grey), // Szürke placeholder
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Kisebb padding
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
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white), // Fehér szöveg a beviteli mezőben
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900], // Sötétszürke háttér
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: 'Enter your password', // Placeholder szöveg
              hintStyle: const TextStyle(color: Colors.grey), // Szürke placeholder
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Kisebb padding
            ),
          ),
        ),
      ],
    );
  }

  Widget _signup(BuildContext context) {
    return SizedBox(
      width: 100, // Szélesség csökkentése
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red, // Piros gomb
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14), // Kisebb padding
          elevation: 0,
        ),
        onPressed: () async {
          await AuthService().signup(
            email: _emailController.text,
            password: _passwordController.text,
            context: context,
          );
        },
        child: Text(
          "Sign Up",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.white, // Fehér szöveg a gombon
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
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