import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'meter_painter.dart';
import 'widgets/buttons/measurement_button.dart';
import 'widgets/Messages/warning_message.dart';
import 'widgets/Messages/success_message.dart';
import '../services/auth_service.dart';
import 'profile_page.dart';
import 'package:dyno2/login/login.dart';
import 'widgets/Messages/result_dialog.dart';
import 'widgets/Messages/help_dialog.dart';
import 'Navbar/button_navbar.dart';

class SpeedMeter extends StatefulWidget {
  const SpeedMeter({super.key});

  @override
  State<SpeedMeter> createState() => _SpeedMeterState();
}

class _SpeedMeterState extends State<SpeedMeter> {
  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  bool isMeasurementActive = false;
  bool isMeasurementStarted = false;
  bool showMovementWarning = false;
  bool showMovementTooHigh = false;
  bool showWarningMessage = false;
  bool isTestButtonVisible = false;
  Timer? _speedIncreaseTimer;
  DateTime? _startTime;
  Timer? _measurementTimer;
  bool _waitingForSpeedToReachThreshold = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  int _selectedIndex = 2;
  int _measurementType = 0;
  bool isKmh = true; // Alapértelmezettként km/h-ban jelenik meg a sebesség


  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    _listenToLocationServiceStatus();
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

  void _toggleSpeedUnit() {
    setState(() {
      isKmh = !isKmh;
    });
  }

  double _getSpeedInCurrentUnit(double speed) {
    return isKmh ? speed : speed * 0.621371192;
  }



  void _updateSpeed(double speed) {
    double newSpeed = speed * 3.6;
    if (newSpeed != currentSpeed) {
      setState(() {
        currentSpeed = newSpeed;
      });
    }

    // Csak akkor induljon el a mérés, ha a mérés aktív
    if (isMeasurementActive) {
      if (_measurementType == 0 && !_waitingForSpeedToReachThreshold && currentSpeed >= 3) {
        _waitingForSpeedToReachThreshold = true;
        _startMeasurementTimer();
      }

      if (_measurementType == 1 && !_waitingForSpeedToReachThreshold && currentSpeed >= 103) {
        _waitingForSpeedToReachThreshold = true;
        _startMeasurementTimer();
      }
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

  void _startMeasurement() {
    setState(() {
      isMeasurementActive = true;
      isMeasurementStarted = true;
      isTestButtonVisible = true;
      _waitingForSpeedToReachThreshold = false;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isMeasurementStarted = false;
      });
    });
  }

  void _startMeasurementTimer() {
    setState(() {
      _startTime = DateTime.now();
    });

    _measurementTimer = Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      if (_measurementType == 0 && currentSpeed >= 100) {
        timer.cancel();
        _finishMeasurement(100);
      }

      if (_measurementType == 1 && currentSpeed >= 200) {
        timer.cancel();
        _finishMeasurement(200);
      }
    });
  }

  void _finishMeasurement(int targetSpeed) {
    if (_startTime != null) {
      final elapsedTime = DateTime.now().difference(_startTime!);
      showResultAndReturnToHomePage(context, elapsedTime, targetSpeed, _resetMeasurement);
    }
  }

  void _resetMeasurement() {
    setState(() {
      isMeasurementActive = false;
      isMeasurementStarted = false;
      isTestButtonVisible = false;
      _waitingForSpeedToReachThreshold = false;
      currentSpeed = 0.0;
      _selectedIndex = 2;
    });

    _measurementTimer?.cancel();
    _measurementTimer = null;
  }

  void _showMovementWarning() {
    setState(() {
      showMovementWarning = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        showMovementWarning = false;
      });
    });
  }

  void _showMovementTooHigh() {
    setState(() {
      showMovementTooHigh = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        showMovementTooHigh = false;
      });
    });
  }

  void _startSpeedIncrease() {
    const double targetSpeed = 200.0;
    const Duration interval = Duration(milliseconds: 100);

    _speedIncreaseTimer = Timer.periodic(interval, (Timer timer) {
      setState(() {
        if (currentSpeed < targetSpeed) {
          currentSpeed += 1.0;
        } else {
          timer.cancel();
        }

        if (_measurementType == 0 && currentSpeed >= 100) {
          _finishMeasurement(100);
        }

        if (_measurementType == 1 && currentSpeed >= 200) {
          _finishMeasurement(200);
        }
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    bool isStopped = currentSpeed < 1;

    if (index == 0) {
      if (isStopped) {
        _measurementType = 0;
        _startMeasurement();
      } else {
        _showMovementWarning();
      }
    } else if (index == 1) {
      if (currentSpeed <= 100) {
        _measurementType = 1;
        _startMeasurement();
      } else {
        _showMovementTooHigh();
      }
    } else if (index == 2) {
      _resetMeasurement();
    } else { //oldalvaltasnal leallitjuk a merest.
      _resetMeasurement();
    }
  }

  void _showHelpDialog() {
    showHelpDialog(context);
  }

  @override
  void dispose() {
    _speedIncreaseTimer?.cancel();
    _measurementTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  bool get _isOnHomePage => _selectedIndex == 2;

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
                  width: isMeasurementActive
                      ? MediaQuery.sizeOf(context).width * 1
                      : MediaQuery.sizeOf(context).width * 0.85,
                  height: isMeasurementActive
                      ? MediaQuery.sizeOf(context).width * 1
                      : MediaQuery.sizeOf(context).width * 0.85,
                    child: GestureDetector(
             onTap: _toggleSpeedUnit,
          child: CustomPaint(
            painter: MeterPainter(_getSpeedInCurrentUnit(currentSpeed), isKmh: isKmh),
          ),
                  ),
                ),
                if (isMeasurementActive) ...[
                  NoOutlineMeasurementButton(
                    onPressed: _resetMeasurement,
                    text: "Mégse",
                    backgroundColor: Colors.red,
                  ),
                  if (isTestButtonVisible)
                    NoOutlineMeasurementButton(
                      onPressed: _startSpeedIncrease,
                      text: "Teszt Sebesség Növelés",
                      backgroundColor: Colors.blue,
                    ),
                ],
              ],
            ),
            if (isMeasurementStarted)
              SuccessMessage(
                message: "A mérés elkezdődött!",
                icon: Icons.check,
                color: Color(0xFF0ca644),
                iconColor: Color(0xFF84D65A),
              ),
            if (showMovementWarning)
              WarningMessage(
                message: "A jármű mozgásban van!",
                icon: Icons.warning,
                color: Colors.orange,
                iconColor: Colors.white,
              ),
            if (showMovementTooHigh)
              WarningMessage(
                message: "100 km/h-t meghaladod!",
                icon: Icons.warning,
                color: Colors.orange,
                iconColor: Colors.white,
              ),

            if (_isOnHomePage)
              Positioned(
                top: 30,
                left: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AuthService().currentUser != null ? Colors.greenAccent : Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.person,
                      color: AuthService().currentUser != null ? Colors.greenAccent : Colors.white,
                    ),
                    iconSize: 20,
                    onPressed: () async {
                      final user = AuthService().currentUser;
                      if (user != null) {
                        final userEmail = user.email ?? "Nincs email cím";
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(userEmail: userEmail),
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

            if (_isOnHomePage)
              Positioned(
                top: 30,
                right: 0,
                child: GestureDetector(
                  onTap: _showHelpDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.question_mark,
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
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
      bottomNavigationBar: isLocationServiceEnabled
          ? BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        currentSpeed: currentSpeed,
        isLocationServiceEnabled: isLocationServiceEnabled,
        showMovementWarning: _showMovementWarning,
        showMovementTooHigh: _showMovementTooHigh,
        onItemTappedInternal: _onItemTapped,
      )
          : null,
    );
  }
}