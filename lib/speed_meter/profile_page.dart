// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:dyno2/widgets/loading_overlay.dart'; // Importáljuk a LoadingOverlay-t
import '../localization/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  const ProfilePage({super.key, required this.userEmail});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _nickname;
  final _nicknameController = TextEditingController();
  final _carController = TextEditingController(); // Add this
  String? _profileImageUrl;
  final _imagePicker = ImagePicker();
  String? _selectedCar;
  bool _isLoading = false; // Aktuális loading állapot tárolásához
  final _instagramController = TextEditingController();
  String? _instagramUsername;

  
  @override
  void initState() {
    super.initState();
    // Use a Future.microtask to ensure mounted checks happen properly
    Future.microtask(() {
      if (mounted) _loadNickname();
      if (mounted) _loadProfileImage();
      if (mounted) _loadSelectedCar();
      if (mounted) _loadInstagramUsername(); // Add this line
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _carController.dispose();
    _instagramController.dispose(); // Add this line
    super.dispose();
  }

  Future<void> _loadNickname() async {
    if (!mounted) return; // Add check before awaiting to exit early
    final nickname = await AuthService().getNickname();
    if (!mounted) return; // Add check after async operation
    setState(() {
      _nickname = nickname;
    });
  }

  Future<void> _updateNickname(String newNickname) async {
    try {
      // Az AuthService fogja ellenőrizni, hogy foglalt-e a név
      await AuthService().updateNickname(newNickname);

      setState(() {
        _nickname = newNickname;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.nicknameUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Hibakezelés, a gomb aktív marad az újrapróbálkozáshoz
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProfileImage() async {
    if (!mounted) return; // Add check before awaiting
    final imageUrl = await AuthService().getProfileImageUrl();
    if (!mounted) return; // Add check after async operation
    setState(() {
      _profileImageUrl = imageUrl;
    });
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );

      if (image == null) return;

      if (!mounted) return; // Check if widget is still mounted before setState
      setState(() {
        _isLoading = true; // Betöltés indítása
      });

      final imageFile = File(image.path);
      final base64Image = await AuthService().uploadProfileImage(imageFile);

      if (!mounted) return; // Check if widget is still mounted before setState
      setState(() {
        _profileImageUrl = base64Image;
        _isLoading = false; // Betöltés befejezése
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.profilePictureUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Hiba esetén is befejezzük a betöltést
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba történt: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSelectedCar() async {
    try {
      if (!mounted) return; // Add check before awaiting
      final car = await AuthService().getSelectedCar();
      if (!mounted) return; // Add check after async operation
      setState(() {
        _selectedCar = car;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading car: $e');
    }
  }

  Future<void> _updateSelectedCar(String car) async {
    try {
      _safeSetState(() {
        _isLoading = true;
      });

      await AuthService().updateSelectedCar(car);

      if (!mounted) return;
      _safeSetState(() {
        _selectedCar = car;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.carUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadInstagramUsername() async {
    try {
      if (!mounted) return;
      final username = await AuthService().getInstagramUsername();
      if (!mounted) return;
      setState(() {
        _instagramUsername = username;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading Instagram username: $e');
    }
  }

  Future<void> _updateInstagramUsername(String username) async {
    try {
      _safeSetState(() {
        _isLoading = true;
      });

      await AuthService().updateInstagramUsername(username);

      if (!mounted) return;
      _safeSetState(() {
        _instagramUsername = username;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.instagramUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _safeSetState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCarSelectionDialog() {
    _carController.text = _selectedCar ?? '';
    bool hasError = false;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.selectCar,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _carController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.enterCarModel,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: hasError ? Colors.red : Colors.white54,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: hasError ? Colors.red : Colors.blue,
                      ),
                    ),
                    counterText: "${_carController.text.length}/25",
                    counterStyle: TextStyle(
                      color: _carController.text.length > 25
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                  maxLength: 25,
                  onChanged: (value) {
                    // Clear error when typing
                    setState(() {
                      hasError = false;
                      errorMessage = '';
                    });
                  },
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    AppLocalizations.carExamples,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.cancel,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final carModel = _carController.text.trim();

                  if (carModel.isEmpty) {
                    setState(() {
                      hasError = true;
                      errorMessage = AppLocalizations.carModelEmpty;
                    });
                    return;
                  }

                  if (carModel.length < 2) {
                    setState(() {
                      hasError = true;
                      errorMessage = AppLocalizations.carModelTooShort;
                    });
                    return;
                  }

                  if (carModel.length > 25) {
                    setState(() {
                      hasError = true;
                      errorMessage = AppLocalizations.carModelTooLong;
                    });
                    return;
                  }

                  _updateSelectedCar(carModel);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppLocalizations.save),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.deleteAccount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.deleteAccountConfirmation,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.cancel,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  );

                  await AuthService().deleteAccount();

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  Navigator.pop(dialogContext);

                  if (!mounted) return;
                  context.go('/login');
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hiba történt: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: Text(
                AppLocalizations.deleteAccount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _changePassword(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isDialogActive = true; // Track if dialog is still active

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return PopScope(
              canPop: !isLoading,
              child: AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'Jelszó módosítás',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 300,
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: currentPasswordController,
                              obscureText: true,
                              enabled: !isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Jelenlegi jelszó',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.white54),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: newPasswordController,
                              obscureText: true,
                              enabled: !isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Új jelszó',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.white54),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              enabled: !isLoading,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Új jelszó megerősítése',
                                labelStyle:
                                    const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.white54),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            isDialogActive =
                                false; // Mark dialog as inactive before closing
                            Navigator.of(dialogContext).pop();
                          },
                    child: Text(
                      AppLocalizations.cancel.toUpperCase(),
                      style: TextStyle(
                        color: isLoading ? Colors.grey : Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            // Store the text values before any async operation
                            final currentPassword =
                                currentPasswordController.text;
                            final newPassword = newPasswordController.text;
                            final confirmPassword =
                                confirmPasswordController.text;

                            if (currentPassword.isEmpty ||
                                newPassword.isEmpty ||
                                confirmPassword.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Minden mező kitöltése kötelező!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Az új jelszavak nem egyeznek!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (currentPassword == newPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Az új jelszó nem lehet ugyanaz, mint a jelenlegi!',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);

                            try {
                              final isCurrentPasswordValid = await AuthService()
                                  .verifyPassword(currentPassword);

                              // Check if dialog is still active before continuing
                              if (!isDialogActive) return;

                              if (!isCurrentPasswordValid) {
                                if (!mounted || !isDialogActive) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('A jelenlegi jelszó helytelen!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                if (isDialogActive) {
                                  setState(() => isLoading = false);
                                }
                                return;
                              }

                              await AuthService().changePassword(newPassword);

                              // Check if dialog is still active before closing
                              if (!mounted || !isDialogActive) return;

                              isDialogActive = false; // Mark dialog as inactive
                              Navigator.of(dialogContext).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Jelszó sikeresen módosítva!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              // Only update state if dialog is still active
                              if (isDialogActive) {
                                setState(() => isLoading = false);
                              }

                              if (!mounted || !isDialogActive) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Hiba történt: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.changePassword.toUpperCase(),
                      style: TextStyle(
                        color: isLoading ? Colors.grey : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Only dispose if dialog is no longer active
      if (isDialogActive) {
        currentPasswordController.dispose();
        newPasswordController.dispose();
        confirmPasswordController.dispose();
        isDialogActive = false;
      }
    });
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.logOut,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.logoutConfirmation,
            style: const TextStyle(color: Colors.white70),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.cancel,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Bezárjuk a dialógust
                  Navigator.pop(dialogContext);

                  // Főoldalon mutatjuk a betöltést
                  if (!mounted) return;
                  _safeSetState(() {
                    _isLoading = true;
                  });

                  await AuthService().signout(context: context);

                  if (mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  // Hibakezelés...
                } finally {
                  if (mounted) {
                    _safeSetState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: Text(
                AppLocalizations.logOut,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitNickname(String value) async {
    if (value.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.emptyNickname),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (value.length > 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.nicknameTooLong),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ellenőrizzük, hogy a jelenlegi becenév nem ugyanaz-e
    if (value == _nickname) {
      _safeSetState(() {});
      return;
    }

    try {
      _safeSetState(() {
        _isLoading = true;
      });

      await _updateNickname(value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Gradient background that extends below the app bar
              Container(
                height: 250, // Extend beyond the app bar
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.red.shade900,
                      Colors.red.shade900.withOpacity(0.7),
                      Colors.red.shade900.withOpacity(0.3),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.3, 0.6, 0.9],
                  ),
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar with transparent background to show gradient behind
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      AppLocalizations.profile,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: true,
                  ),

                  // Content with spacing to start after the gradient fade
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        children: [
                          // Profile header with avatar
                          _buildProfileHeader(),

                          const SizedBox(height: 24),

                          // Main sections
                          _buildSectionHeader(
                              AppLocalizations.accountInformation),
                          const SizedBox(height: 16),
                          _buildInfoCard(),

                          const SizedBox(height: 24),

                          _buildSectionHeader(AppLocalizations.accountSettings),
                          const SizedBox(height: 16),
                          _buildActionButtonsGroup(),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Background card with gradient border
        Container(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.fromLTRB(16, 70, 16, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                _nickname ?? 'No Nickname',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.userEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEditButton(
                    AppLocalizations.editNickname,
                    Icons.edit,
                    Colors.red,
                    () {
                      _nicknameController.text = _nickname ?? '';
                      setState(() {});
                      _showEditNicknameDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Positioned avatar with red glow
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _updateProfileImage,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade800,
                    Colors.red.shade400,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.black,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: _profileImageUrl != null
                      ? Image.memory(
                          base64Decode(_profileImageUrl!),
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
          ),
        ),

        // Camera icon button
        Positioned(
          top: 5,
          right: 0,
          left: 70,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
              onPressed: _updateProfileImage,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            AppLocalizations.car,
            _selectedCar ?? AppLocalizations.noCarSelected,
            Icons.directions_car,
            Colors.blue,
            _showCarSelectionDialog,
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          _buildInfoRow(
            AppLocalizations.instagram,
            _instagramUsername != null && _instagramUsername!.isNotEmpty
                ? '@$_instagramUsername'
                : AppLocalizations.noInstagramUsername,
            Icons.photo_camera,
            Colors.pink,
            _showInstagramUsernameDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsGroup() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildActionRow(
            AppLocalizations.changePassword,
            Icons.lock_outline,
            Colors.green,
            () => _changePassword(context),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          _buildActionRow(
            AppLocalizations.logOut,
            Icons.logout,
            Colors.red.shade400,
            () => _showLogoutConfirmationDialog(context),
          ),
          const Divider(height: 1, color: Color(0xFF333333)),
          _buildActionRow(
            AppLocalizations.deleteAccount,
            Icons.delete_outline,
            Colors.red.shade900,
            () => _showDeleteConfirmationDialog(context),
            isDangerous: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    String label,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed, {
    bool isDangerous = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDangerous ? Colors.red.shade400 : Colors.white,
                  fontSize: 16,
                  fontWeight: isDangerous ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to your _ProfilePageState class
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Add method to show Instagram username dialog
  void _showInstagramUsernameDialog() {
    _instagramController.text = _instagramUsername ?? '';

    // Track if validation error exists
    bool hasError = false;
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Row(
              children: [
                const Icon(Icons.photo_camera, color: Colors.pink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.instagramUsername,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: TextField(
                    controller: _instagramController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.enterInstagramUsername,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: hasError ? Colors.red : Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: hasError ? Colors.red : Colors.pink),
                      ),
                      counterText: "${_instagramController.text.length}/30",
                      counterStyle: TextStyle(
                        color: _instagramController.text.length > 30
                            ? Colors.red
                            : Colors.grey,
                      ),
                      prefixText: '@',
                      prefixStyle: const TextStyle(color: Colors.pink),
                    ),
                    maxLength: 30,
                    onChanged: (value) {
                      setState(() {
                        // Clear error when user types
                        hasError = false;
                        errorMessage = '';

                        // Check for invalid characters in real-time
                        if (value.contains(' ')) {
                          hasError = true;
                          errorMessage = AppLocalizations.usernameNoSpaces;
                        }

                        // Check for special characters except underscore and period
                        final invalidChars = RegExp(r'[^\w.]');
                        if (invalidChars.hasMatch(value)) {
                          hasError = true;
                          errorMessage = AppLocalizations.usernameInvalidChars;
                        }
                      });
                    },
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    AppLocalizations.instagramUsernameInfo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.cancel,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final username = _instagramController.text.trim();

                  // Validate before saving
                  if (username.length > 30) {
                    setState(() {
                      hasError = true;
                      errorMessage = AppLocalizations.usernameMaxLength;
                    });
                    return;
                  }

                  if (username.contains(' ')) {
                    setState(() {
                      hasError = true;
                      errorMessage = AppLocalizations.usernameNoSpaces;
                    });
                    return;
                  }

                  // Check for special characters except underscore and period
                  final invalidChars = RegExp(r'[^\w.]');
                  if (invalidChars.hasMatch(username)) {
                    setState(() {
                      hasError = true;
                      errorMessage = AppLocalizations.usernameInvalidChars;
                    });
                    return;
                  }

                  _updateInstagramUsername(username);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppLocalizations.save),
              ),
            ],
          );
        });
      },
    );
  }

  // Add this new method to handle nickname editing with a dialog
  void _showEditNicknameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.editNickname,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: TextField(
          controller: _nicknameController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.enterNickname,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF212121),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterText: '${_nicknameController.text.length}/10',
            counterStyle: TextStyle(
              color: _nicknameController.text.length > 10
                  ? Colors.red
                  : Colors.grey,
            ),
          ),
          maxLength: 10,
          onChanged: (value) {
            setState(() {});
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: Text(AppLocalizations.cancel.toUpperCase()),
          ),
          ElevatedButton(
            onPressed: () {
              _submitNickname(_nicknameController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.save.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
