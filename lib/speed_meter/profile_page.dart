// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadProfileImage();
    _loadSelectedCar(); // Add this
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _carController.dispose(); // Add this
    super.dispose();
  }

  Future<void> _loadNickname() async {
    final nickname = await AuthService().getNickname();
    setState(() {
      _nickname = nickname;
    });
  }

  Future<void> _updateNickname(String newNickname) async {
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba történt: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadProfileImage() async {
    final imageUrl = await AuthService().getProfileImageUrl();
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

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );

      final imageFile = File(image.path);
      final base64Image = await AuthService().uploadProfileImage(imageFile);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        _profileImageUrl = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilkép sikeresen módosítva!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
      final car = await AuthService().getSelectedCar();
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
      await AuthService().updateSelectedCar(car);
      setState(() {
        _selectedCar = car;
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
                  // Show loading indicator
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    ),
                  );

                  await AuthService().signout(context: context);

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext); // Close loading
                  Navigator.pop(dialogContext); // Close dialog

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
                  hintText: 'Add meg a beceneved',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _updateNickname(value);
                  }
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
                if (_nicknameController.text.isNotEmpty) {
                  _updateNickname(_nicknameController.text);
                }
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
    return Scaffold(
      backgroundColor: Colors.black,
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
}
