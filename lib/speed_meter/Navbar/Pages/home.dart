import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../meter_painter.dart';
import '../../../services/auth_service.dart';
import '../../profile_page.dart';
import 'package:dyno2/login/login.dart';
import '../../widgets/Messages/help_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool isKmh = true; // Default to km/h

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    _listenToLocationServiceStatus();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _checkPermissionsAndStartListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      isLocationServiceEnabled = serviceEnabled;
    });

    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(milliseconds: 100),
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      _updateSpeed(position.speed);
    });
  }

  void _updateSpeed(double speed) {
    double newSpeed = speed * 3.6;
    if (newSpeed != currentSpeed) {
      setState(() {
        currentSpeed = newSpeed;
      });
    }
  }

  void _listenToLocationServiceStatus() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      bool isEnabled = status == ServiceStatus.enabled;
      setState(() {
        isLocationServiceEnabled = isEnabled;
      });
      if (isEnabled) {
        _checkPermissionsAndStartListening();
      }
    });
  }

  void _toggleSpeedUnit() {
    setState(() {
      isKmh = !isKmh;
    });
  }

  double _getSpeedInCurrentUnit(double speed) {
    return isKmh ? speed : speed * 0.621371192;
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
                'Beállítások',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Speed unit setting
                  ListTile(
                    title: const Text(
                      'Sebesség mértékegység',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: DropdownButton<bool>(
                      dropdownColor: Colors.grey[850],
                      value: isKmh,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          setState(() {
                            isKmh = newValue;
                          });
                          this.setState(() {
                            isKmh = newValue;
                          });
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
                  // Language button (inactive)
                  ListTile(
                    title: const Text(
                      'Nyelv',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: TextButton(
                      onPressed: null, // Disabled for now
                      child: const Text(
                        'Magyar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  // Information button
                  ListTile(
                    title: const Text(
                      'Információk',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                        _showHelpDialog();
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Bezár',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
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
        child: isLocationServiceEnabled
            ? Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: MediaQuery.sizeOf(context).width * 0.85,
                        height: MediaQuery.sizeOf(context).width * 0.85,
                        child: GestureDetector(
                          onTap: _toggleSpeedUnit,
                          child: CustomPaint(
                            painter: MeterPainter(
                                _getSpeedInCurrentUnit(currentSpeed),
                                isKmh: isKmh),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(userEmail: userEmail),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Login(),
                              ),
                            );
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
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 60,
                    color: Colors.red,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Location disabled",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "To use the app, location services must be enabled in the settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Geolocator.openLocationSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Open Settings",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
