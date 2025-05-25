import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dyno2/speed_meter/widgets/Messages/warning_message.dart';
import 'package:dyno2/widgets/loading_overlay.dart'; // Importáljuk a LoadingOverlay-t
import 'package:dyno2/localization/app_localizations.dart';

class Signup extends StatefulWidget {
  // Change to StatefulWidget
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Add this
  bool _isPasswordVisible = false; // Add this variable
  bool _isConfirmPasswordVisible = false; // Add this
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasNumber = false;
  bool _isEmailValid = false;
  bool _isLoading = false; // Betöltési állapot hozzáadása

  // Add new state variables for warning messages
  bool showPasswordRequirementsWarning = false;
  bool showPasswordMismatchWarning = false;
  bool showEmailWarning = false; // Add this variable

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: _signin(context),
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
                          AppLocalizations.registerAccount,
                          style: GoogleFonts.raleway(
                            textStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _emailAddress(),
                        const SizedBox(height: 20),
                        _password(),
                        const SizedBox(height: 20),
                        _confirmPassword(),
                        const SizedBox(height: 16),
                        // Password requirements moved here
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPasswordRequirement(
                                isValid: _hasMinLength,
                                text: AppLocalizations.atLeast8Chars,
                              ),
                              const SizedBox(height: 8),
                              _buildPasswordRequirement(
                                isValid: _hasUpperCase,
                                text: AppLocalizations.atLeastOneUppercase,
                              ),
                              const SizedBox(height: 8),
                              _buildPasswordRequirement(
                                isValid: _hasNumber,
                                text: AppLocalizations.atLeastOneNumber,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _signup(context),
                      ],
                    ),
                  ),
                ), // Add warning messages
                if (showPasswordRequirementsWarning)
                  WarningMessage(
                    key: const Key('requirementsWarning'),
                    message: AppLocalizations.meetPasswordRequirements,
                    icon: Icons.warning,
                    color: Colors.red,
                    iconColor: Colors.white,
                  ),
                if (showPasswordMismatchWarning)
                  WarningMessage(
                    key: const Key('mismatchWarning'),
                    message: AppLocalizations.passwordsDontMatch,
                    icon: Icons.warning,
                    color: Colors.red,
                    iconColor: Colors.white,
                  ),
                if (showEmailWarning)
                  WarningMessage(
                    key: const Key('emailWarning'),
                    message: AppLocalizations.enterValidEmail,
                    icon: Icons.warning,
                    color: Colors.red,
                    iconColor: Colors.white,
                  ),
              ],
            ),
          ),
        ),
        // LoadingOverlay hozzáadása
        if (_isLoading) const LoadingOverlay(),
      ],
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
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _isEmailValid = _validateEmail(value);
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: AppLocalizations.enterYourEmail,
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              // Add validation indicator
              suffixIcon: Icon(
                _isEmailValid ? Icons.check_circle : Icons.error,
                color: _isEmailValid ? Colors.green : Colors.grey,
              ),
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
            onChanged: _checkPasswordConditions,
          ),
        ),
      ],
    );
  }

  Widget _confirmPassword() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.confirmPassword,
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 300,
          child: TextField(
            obscureText: !_isConfirmPasswordVisible,
            controller: _confirmPasswordController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              hintText: AppLocalizations.confirmYourPassword,
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
              onTap: _isLoading
                  ? null
                  : () async {
                      // Letiltjuk betöltés közben
                      // Check email validity first
                      if (!_isEmailValid) {
                        _showWarning('email');
                        return;
                      }

                      // Check password conditions
                      if (!_hasMinLength || !_hasUpperCase || !_hasNumber) {
                        _showWarning('requirements');
                        return;
                      }

                      if (_passwordController.text !=
                          _confirmPasswordController.text) {
                        _showWarning('mismatch');
                        return;
                      }

                      // Betöltési állapot beállítása
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        await AuthService().signup(
                          email: _emailController.text,
                          password: _passwordController.text,
                          context: context,
                        );
                        // A sikeres regisztráció után a context.go() átnavigál,
                        // így nem kell a betöltést kikapcsolni
                      } catch (e) {
                        // Hiba esetén megállítjuk a betöltést
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          // Itt lehetne hibaüzenetet megjeleníteni
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text("Registration failed: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey
                      : Colors.red, // Szürke, ha betöltés alatt áll
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.signUp,
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
              onTap: _isLoading
                  ? null
                  : () {
                      // Letiltjuk betöltés közben
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
                    AppLocalizations.back,
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
              text: AppLocalizations.alreadyHaveAccount,
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  color: Colors.grey, // Szürke szöveg
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            TextSpan(
              text: AppLocalizations.logIn,
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

  void _checkPasswordConditions(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  // Add this helper method to build requirement indicators
  Widget _buildPasswordRequirement({
    required bool isValid,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Add method to show warning messages
  void _showWarning(String type) {
    setState(() {
      showPasswordRequirementsWarning = false;
      showPasswordMismatchWarning = false;
      showEmailWarning = false; // Add this variable to class properties

      switch (type) {
        case 'email':
          showEmailWarning = true;
          break;
        case 'requirements':
          showPasswordRequirementsWarning = true;
          break;
        case 'mismatch':
          showPasswordMismatchWarning = true;
          break;
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showPasswordRequirementsWarning = false;
          showPasswordMismatchWarning = false;
          showEmailWarning = false;
        });
      }
    });
  }

  // Add this validation method
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }
}
