import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../meter_painter.dart';
import '../../../services/auth_service.dart';
import '../../widgets/Messages/help_dialog.dart';
import '../../../providers/speed_provider.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeedProvider _speedProvider = SpeedProvider();
  bool isKmh = true;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    _listenToLocationServiceStatus();

    // Add listener to get notified when speed changes
    _speedProvider.addListener(_onSpeedChanged);
  }

  void _onSpeedChanged() {
    // Force rebuild when speed changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Cancel the location service status subscription
    _serviceStatusSubscription?.cancel();

    // Remove listener when widget is disposed
    _speedProvider.removeListener(_onSpeedChanged);
    // Note: Do not call _speedProvider.dispose() here as it might be used by other widgets
    // We'll only remove our listener to avoid memory leaks
    super.dispose();
  }

  void _checkPermissionsAndStartListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        _speedProvider.isLocationServiceEnabled = serviceEnabled;
      });
    }

    if (!serviceEnabled || !mounted) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || !mounted) return;
    }

    _speedProvider.startSpeedTracking();
  }

  void _listenToLocationServiceStatus() {
    _serviceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      bool isEnabled = status == ServiceStatus.enabled;
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          _speedProvider.isLocationServiceEnabled = isEnabled;
        });
        if (isEnabled) {
          _checkPermissionsAndStartListening();
        }
      }
    });
  }

  void _showHelpDialog() {
    showHelpDialog(context);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Speed Unit Setting
                  ListTile(
                    title: const Text(
                      'Speed Unit',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: DropdownButton<bool>(
                      dropdownColor: Colors.grey[850],
                      value: _speedProvider.isKmh,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          _speedProvider.setSpeedUnit(newValue);
                          setState(() {});
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('km/h',
                              style: TextStyle(color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('mph',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  // Information Button
                  ListTile(
                    title: const Text(
                      'Information',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close settings dialog
                        _showHelpDialog(); // Show help dialog
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: MediaQuery.sizeOf(context).width * 0.85,
                  height: MediaQuery.sizeOf(context).width * 0.85,
                  child: CustomPaint(
                    painter: MeterPainter(
                      _speedProvider
                          .getCurrentSpeed(), // Használjuk az új getCurrentSpeed() metódust
                      isKmh: _speedProvider.isKmh,
                      hasGpsSignal: _speedProvider.hasGpsSignal,
                    ),
                  ),
                ),
              ],
            ),
            // Profil ikon a bal felső sarokban
            Positioned(
              top: 30,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AuthService().currentUser != null
                          ? Colors.greenAccent
                          : Colors.white,
                      width: 2),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.person,
                    color: AuthService().currentUser != null
                        ? Colors.greenAccent
                        : Colors.white,
                  ),
                  iconSize: 20,
                  onPressed: () async {
                    final user = AuthService().currentUser;
                    if (user != null) {
                      final userEmail = user.email ?? "Nincs email cím";
                      context.push('/profile', extra: userEmail);
                    } else {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ),
            // Kérdőjel ikon a jobb felső sarokban
            Positioned(
              top: 30,
              right: 0,
              child: GestureDetector(
                onTap: _showSettingsDialog,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.settings,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
