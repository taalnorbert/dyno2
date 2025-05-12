import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:dyno2/speed_meter/widgets/Messages/warning_message.dart';

class AuthService {
  final logger = Logger();
  get userStream => null;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Get user ID before deletion
        final String uid = user.uid;

        // Delete all user data from Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // Delete any other collections related to the user
        // For example, if you have user-specific measurements or records
        await _deleteUserRelatedData(uid);

        // Finally delete the user account
        await user.delete();
      }
    } catch (e) {
      logger.e('Account deletion error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Helper method to delete all user-related data
  Future<void> _deleteUserRelatedData(String uid) async {
    try {
      // Add all collections that contain user-specific data
      final collections = [
        'measurements',
        'laptimes',
        'dynoResults',
        // Add any other collections that store user data
      ];

      // Delete data from each collection
      for (String collection in collections) {
        // Get all documents where userId matches
        final querySnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('userId', isEqualTo: uid)
            .get();

        // Delete each document
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      logger.e('Delete user data error:',
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

  void showWarningMessage(BuildContext context, String message, Color color) {
    // Ensure we have a valid context and the overlay is available
    if (!context.mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    // Create an overlay entry
    final overlayEntry = OverlayEntry(
      builder: (context) => WarningMessage(
        message: message,
        icon: Icons.warning,
        color: color,
        iconColor: Colors.white,
      ),
    );

    // Insert the overlay
    overlay.insert(overlayEntry);

    // Remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      // Check if the overlay entry is still valid before removing
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Add method to handle warning messages safely
  void _showWarningMessageSafe(
      BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    showWarningMessage(context, message, color);
  }

  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Create the user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store registration time and user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'registrationTime': FieldValue.serverTimestamp(),
        'isVerified': false,
      });

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Schedule deletion after 24 hours if not verified
      Future.delayed(const Duration(hours: 24), () async {
        // Check if user exists and is still not verified
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          // Get user data from Firestore
          final userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          // Delete user if still not verified
          if (userData.exists && userData.data()?['isVerified'] == false) {
            await user.delete();
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .delete();
          }
        }
      });

      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      _showWarningMessageSafe(
        context,
        "Registration successful! Please verify your email within 24 hours or your account will be deleted.",
        Colors.green,
      );

      if (!context.mounted) return;
      context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String message;

      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with that email.';
          break;
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password registration is not enabled.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Try again later.';
          break;
        default:
          message = 'Registration error: ${e.message}';
      }
      _showWarningMessageSafe(context, message, Colors.red);
    } on SocketException {
      if (!context.mounted) return;
      _showWarningMessageSafe(
        context,
        'No internet connection. Please check your network settings.',
        Colors.red,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showWarningMessageSafe(
        context,
        'Unexpected error: ${e.toString()}',
        Colors.red,
      );
    }
  }

  // Add method to mark user as verified when they verify their email
  Future<void> _markUserAsVerified(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isVerified': true});
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
      if (!context.mounted) return;
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!context.mounted) return;
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showWarningMessageSafe(
          // ignore: use_build_context_synchronously
          context,
          "Please verify your email before logging in. Check your inbox.",
          Colors.orange,
        );

        if (!context.mounted) return;
        bool? resendEmail = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
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
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child:
                      const Text('Resend', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );

        if (resendEmail == true) {
          if (!context.mounted) return;
          userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          await userCredential.user?.sendEmailVerification();

          if (!context.mounted) return;
          _showWarningMessageSafe(
            context,
            "Verification email resent. Please check your inbox.",
            Colors.green,
          );
        }
        return;
      } else {
        // Mark user as verified in Firestore if email is verified
        await _markUserAsVerified(userCredential.user!.uid);
        if (!context.mounted) return;
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String message = 'An error occurred during sign in';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      }

      // Ahelyett hogy csak a context-be küldenénk a hibát,
      // dobjunk egy konkrét exception-t, amit a hívó kezelhet
      throw Exception(message);
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

  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      // Ellenőrizzük, hogy a becenév már foglalt-e (bármely felhasználó által)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .get();

      // Ha üres a lekérdezés eredménye, akkor a becenév még szabad
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      logger.e('Nickname availability check error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateNickname(String nickname) async {
    try {
      // Ellenőrizzük, hogy a becenév már foglalt-e
      final isAvailable = await isNicknameAvailable(nickname);
      if (!isAvailable) {
        throw Exception('Ez a becenév már foglalt!');
      }

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
      showWarningMessage(
        // ignore: use_build_context_synchronously
        context,
        "Password reset email sent. Please check your inbox.",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      }
      // ignore: use_build_context_synchronously
      showWarningMessage(context, message, Colors.red);
    }
  }

  Future<String?> getSelectedCar() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return doc.data()?['selectedCar'] as String?;
      }
      return null;
    } catch (e) {
      logger.e('Get selected car error:',
          error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> updateSelectedCar(String car) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'selectedCar': car,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      logger.e('Update car error:', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<void> saveMeasurement(String type, double time) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('measurements').add({
          'userId': user.uid,
          'type':
              type, // 'zero-to-hundred', 'hundred-to-twohundred', 'quarter-mile'
          'time': time,
          'car': await getSelectedCar() ?? 'Unknown Car',
          'date': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      logger.e('Save measurement error:',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserMeasurements(String type) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Debug the query parameters
        // ignore: avoid_print
        print('Querying measurements with userId: ${user.uid}, type: $type');

        final snapshot = await FirebaseFirestore.instance
            .collection('measurements')
            .where('userId', isEqualTo: user.uid)
            .where('type', isEqualTo: type)
            .orderBy('date',
                descending: true) // Rendezés dátum szerint csökkenő sorrendben
            .get();

        // Debug what was found
        // ignore: avoid_print
        print('Found ${snapshot.docs.length} measurements for type $type');

        return snapshot.docs
            .map((doc) {
              try {
                return {
                  'username': 'Te',
                  'car': doc.data().containsKey('car')
                      ? doc.data()['car'] as String
                      : 'Unknown Car',
                  'time': doc.data().containsKey('time')
                      ? (doc.data()['time'] as num).toDouble()
                      : 0.0,
                  'date': doc.data()['date'],
                };
              } catch (e) {
                // ignore: avoid_print
                print('Error mapping document: $e');
                return null;
              }
            })
            .where((map) => map != null)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Error getting measurements: $e');
      return [];
    }
  }
}
