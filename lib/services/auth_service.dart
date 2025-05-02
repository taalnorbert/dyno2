import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';

class AuthService {
  final logger = Logger();
  get userStream => null;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      logger.e('Account deletion error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      logger.e('Password change error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Create user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Sign out the user immediately after registration
      await FirebaseAuth.instance.signOut();

      // Show success toast
      Fluttertoast.showToast(
        msg:
            "Registration successful! Please check your email to verify your account.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      // Navigate to login page instead of home
      // ignore: use_build_context_synchronously
      context.go('/login');
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  // Add method to check email verification status
  bool isEmailVerified() {
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  // Add method to resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Fluttertoast.showToast(
          msg: "Verification email resent. Please check your inbox.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    } catch (e) {
      logger.e('Email verification error:',
          error: e, stackTrace: StackTrace.current);
      Fluttertoast.showToast(
        msg: "Failed to send verification email. Please try again later.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut(); // Sign out if email not verified
        Fluttertoast.showToast(
          msg: "Please verify your email before logging in. Check your inbox.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          fontSize: 14.0,
        );

        // Add option to resend verification email
        bool? resendEmail = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Email Not Verified',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                'Would you like to resend the verification email?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Resend', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );

        if (resendEmail == true) {
          await userCredential.user?.sendEmailVerification();
          Fluttertoast.showToast(
            msg: "Verification email resent. Please check your inbox.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
        return;
      }

      // If email is verified, proceed with login
      // ignore: use_build_context_synchronously
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred during sign in';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signout({
    required BuildContext context,
  }) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    context.go('/login');
  }

  Future<bool> verifyPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      logger.e('Password verification error:',
          error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<void> updateNickname(String nickname) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': nickname,
          'email': user.email,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      logger.e('Nickname update error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<String?> getNickname() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return doc.data()?['nickname'] as String?;
      }
      return null;
    } catch (e) {
      logger.e('Get nickname error:', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<String?> getProfileImageUrl() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return doc.data()?['profileImage'] as String?;
      }
      return null;
    } catch (e) {
      logger.e('Get profile image error:',
          error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Convert image to base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Save the base64 string to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImage': base64Image,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return base64Image;
      }
      return null;
    } catch (e) {
      logger.e('Upload profile image error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Add this method to AuthService class
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show success message
      Fluttertoast.showToast(
        msg: "Password reset email sent. Please check your inbox.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }
}
