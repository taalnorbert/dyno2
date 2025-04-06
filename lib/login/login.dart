import 'package:dyno2/signup/signup.dart';
import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dyno2/speed_meter/speedmeter.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // AuthService példányosítása

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
          return SpeedMeter(); // Itt a SpeedMeter a főoldal
        } else {
          // Ha nincs bejelentkezve, jelenítsd meg a bejelentkezési képernyőt
          return Scaffold(
            backgroundColor: Colors.black, // Fekete háttér
            resizeToAvoidBottomInset: true,
            bottomNavigationBar: _signup(context),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Tartalom középre igazítása
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
                      const SizedBox(height: 40), // Kisebb távolság a cím és a mezők között
                      _emailAddress(),
                      const SizedBox(height: 20),
                      _password(),
                      const SizedBox(height: 30), // Kisebb távolság a mezők és a gomb között
                      _combinedLoginButtons(context), // Kombinált gomb
                    ],
                  ),
                ),
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
            obscureText: true,
            controller: _passwordController,
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
                await _authService.signin(
                  email: _emailController.text,
                  password: _passwordController.text,
                  context: context,
                );
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
                // Navigálj a SpeedMeter oldalra
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => const SpeedMeter(),
                  ),
                );
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Signup()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}