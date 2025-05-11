// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:dyno2/widgets/loading_overlay.dart'; // Importáljuk a LoadingOverlay-t

class ProfilePage extends StatefulWidget {
  final String userEmail;
  const ProfilePage({super.key, required this.userEmail});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _nickname;
  bool _isEditingNickname = false;
  final _nicknameController = TextEditingController();
  final _carController = TextEditingController(); // Add this
  String? _profileImageUrl;
  final _imagePicker = ImagePicker();
  String? _selectedCar;
  bool _isLoading = false; // Aktuális loading állapot tárolásához

  @override
  void initState() {
    super.initState();
    // Use a Future.microtask to ensure mounted checks happen properly
    Future.microtask(() {
      if (mounted) _loadNickname();
      if (mounted) _loadProfileImage();
      if (mounted) _loadSelectedCar();
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _carController.dispose(); // Add this
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
        _isEditingNickname = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Becenév sikeresen módosítva!'),
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
        const SnackBar(
          content: Text('Profilkép sikeresen módosítva!'),
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
        const SnackBar(
          content: Text('Car updated successfully!'),
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
    _carController.text = _selectedCar ?? ''; // Set initial value

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Select Car',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: TextField(
            controller: _carController, // Use the class property
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter car model',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_carController.text.isNotEmpty) {
                  _updateSelectedCar(_carController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        );
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
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Fiók törlése',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Biztosan törölni szeretnéd a fiókodat?\nEz a művelet nem visszavonható!',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Mégse',
                style: TextStyle(color: Colors.white70, fontSize: 16),
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
              child: const Text(
                'Törlés',
                style: TextStyle(
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
                      'Mégse',
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
                      'Módosítás',
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
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Kijelentkezés',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Biztosan ki szeretnél jelentkezni?',
            style: TextStyle(color: Colors.white70),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Mégse',
                style: TextStyle(color: Colors.white70, fontSize: 16),
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
              child: const Text(
                'Kijelentkezés',
                style: TextStyle(
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

  Widget _buildNicknameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, color: Colors.blue),
          const SizedBox(width: 10),
          if (_isEditingNickname)
            Expanded(
              child: TextField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Max 10 karakter',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  counterText: "${_nicknameController.text.length}/10",
                  counterStyle: TextStyle(
                    color: _nicknameController.text.length > 10
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
                maxLength: 10, // Korlátozás 10 karakterre
                onSubmitted: _submitNickname,
                onChanged: (value) {
                  // Az onChanged miatt frissül a számláló
                  setState(() {});
                },
              ),
            )
          else
            Text(
              _nickname ?? 'Nincs becenév',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(
              _isEditingNickname ? Icons.check : Icons.edit,
              color: Colors.blue,
              size: 20,
            ),
            onPressed: () {
              if (_isEditingNickname) {
                _submitNickname(_nicknameController.text);
              } else {
                _nicknameController.text = _nickname ?? '';
                setState(() {
                  _isEditingNickname = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitNickname(String value) async {
    if (value.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A becenév nem lehet üres!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (value.length > 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A becenév maximum 10 karakter lehet!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ellenőrizzük, hogy a jelenlegi becenév nem ugyanaz-e
    if (value == _nickname) {
      _safeSetState(() {
        _isEditingNickname = false;
      });
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

  Widget _buildProfileAvatar() {
    return GestureDetector(
      onTap: _updateProfileImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
              color: Colors.grey[900],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: _profileImageUrl != null
                  ? Image.memory(
                      base64Decode(_profileImageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blue,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue,
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileAvatar(), // Replace the existing Container with this
                  const SizedBox(height: 20),
                  // Nickname Section
                  _buildNicknameSection(),
                  const SizedBox(height: 15),
                  // Email Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(
                          widget.userEmail,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(
                          _selectedCar ?? 'No car selected',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: _showCarSelectionDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Action Buttons
                  _buildActionButton(
                    icon: Icons.lock,
                    label: 'Jelszó módosítása',
                    color: Colors.green,
                    onPressed: () => _changePassword(context),
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Fiók törlése',
                    color: Colors.red.shade900,
                    onPressed: () => _showDeleteConfirmationDialog(context),
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    icon: Icons.logout,
                    label: 'Kijelentkezés',
                    color: Colors.red,
                    onPressed: () => _showLogoutConfirmationDialog(context),
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    icon: Icons.directions_car,
                    label: 'Select Car',
                    color: Colors.blue,
                    onPressed: _showCarSelectionDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading) const LoadingOverlay(),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
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
}
