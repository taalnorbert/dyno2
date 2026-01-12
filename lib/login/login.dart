import 'dart:async';

import 'package:dyno2/services/auth_service.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/home.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:dyno2/speed_meter/widgets/Messages/warning_message.dart';
import 'package:dyno2/widgets/loading_overlay.dart';
import 'package:dyno2/localization/app_localizations.dart';

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
  bool _isPasswordVisible = false;
  bool showLoginError = false;
  String errorMessage = '';
  bool _isLoading = false;

  // Add method to show warning
  void _showWarning(String message) {
    setState(() {
      errorMessage = message;
      showLoginError = true;
      _isLoading = false; // Explicit stop loading when showing warning
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showLoginError = false;
        });
      }
    });
  }

  // Módosított login kezelés
  void _handleLogin() async {
    // Ellenőrizzük, hogy van-e megadva email és jelszó
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showWarning(AppLocalizations.enterEmailAndPassword);
      return;
    }

    setState(() {
      _isLoading = true; // Betöltés indítása
    });

    try {
      final success = await AuthService().signin(
        email: _emailController.text,
        password: _passwordController.text,
        context: context,
      );

      // Ha nem sikerült a bejelentkezés (pl. nincs megerősítve az email)
      if (!success) {
        setState(() {
          _isLoading = false;
        });
      }
      // Sikeres bejelentkezés esetén a StreamBuilder automatikusan átirányít
    } catch (e) {
      // Explicit módon állítsuk le a betöltést és mutassuk a hibaüzenetet
      setState(() {
        _isLoading = false;

        // Clean up the error message by removing "Exception: " prefix
        String errorMsg = e.toString();
        if (errorMsg.startsWith("Exception: ")) {
          errorMsg = errorMsg.substring("Exception: ".length);
        }

        _showWarning(errorMsg);
      });
    }
  }

  Widget _googleSignInButton() {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google_logo.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.signInWithGoogle,
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kezelőfüggvény a Google bejelentkezéshez
  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Indítsuk el a Google bejelentkezést - egyszerűsített verzió, kevesebb várakozással
      final userCredential = await _authService.signInWithGoogle();

      // Közvetlenül ellenőrizzük az eredményt, nem használunk Completert
      if (userCredential == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _showWarning(AppLocalizations.googleSignInCanceled);
          });
        }
        return;
      }

      // Explicit módon állítsuk le a betöltést, ha mégsem frissülne a UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Ha a UI nem frissül automatikusan, explicit módon navigáljunk
      if (mounted && _authService.currentUser != null) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showWarning(
              '${AppLocalizations.googleSignInError}: ${e.toString()}');
        });
      }
    }
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
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          // Ha be van jelentkezve, navigálj a főoldalra
          return HomePage(); // Itt a SpeedMeter a főoldal
        } else {
          // Ha nincs bejelentkezve, jelenítsd meg a bejelentkezési képernyőt
          return Stack(
            children: [
              Scaffold(
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.loginTitle,
                                style: GoogleFonts.raleway(
                                  textStyle: const TextStyle(
                                    color: Colors.red, // Piros szöveg
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              _emailAddress(),
                              const SizedBox(height: 20),
                              _password(),
                              _forgotPassword(),
                              const SizedBox(height: 20),
                              _combinedLoginButtons(context),

                              // Vagy szöveg, vagy elválasztó
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 1,
                                      color: Colors.grey[700],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        AppLocalizations.or,
                                        style:
                                            TextStyle(color: Colors.grey[500]),
                                      ),
                                    ),
                                    Container(
                                      width: 100,
                                      height: 1,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),

                              // Google bejelentkezés gomb
                              _googleSignInButton(),
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
              ),
              // Itt használom a LoadingOverlay-t a korábbi egyedi megoldás helyett
              if (_isLoading)
                LoadingOverlay(
                  onTimeout: () {
                    // Ez fog lefutni, ha az overlay időtúllépés miatt bezáródna
                    setState(() {
                      _isLoading = false;
                    });
                    // Megjelenítünk egy hibaüzenetet
                    _showWarning(AppLocalizations.operationTimedOut);
                  },
                ),
            ],
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
          AppLocalizations.emailAddress,
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
              hintText: AppLocalizations.enterYourEmail, // Placeholder szöveg
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
          AppLocalizations.password,
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
              hintText:
                  AppLocalizations.enterYourPassword, // Placeholder szöveg
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
              onTap:
                  _isLoading ? null : _handleLogin, // Letiltjuk betöltés közben
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
                    AppLocalizations.signIn,
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
                    AppLocalizations.guest,
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
              text: AppLocalizations.newUser,
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Colors.grey, // Szürke szöveg
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            TextSpan(
              text: AppLocalizations.createAccount,
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
                  title: Text(
                    AppLocalizations.resetPassword,
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.enterEmailToResetPassword,
                        style: const TextStyle(color: Colors.white70),
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
                          hintText: AppLocalizations.emailAddress,
                          hintStyle: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.cancel,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        _authService.resetPassword(
                          email: emailController.text,
                          context: context,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.reset,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          child: Text(
            AppLocalizations.forgotPassword,
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
}
