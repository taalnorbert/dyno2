import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../meter_painter.dart';
import '../../widgets/buttons/measurement_button.dart';
import '../../widgets/Messages/warning_message.dart';
import '../../widgets/Messages/success_message.dart';
import '../../widgets/Messages/result_dialog.dart';
import '../../../providers/speed_provider.dart'; // Import the SpeedProvider
import '../../widgets/location_disabled_screen.dart';

class ZeroToHundred extends StatefulWidget {
  const ZeroToHundred({super.key});

  @override
  State<ZeroToHundred> createState() => _ZeroToHundredState();
}

class _ZeroToHundredState extends State<ZeroToHundred> {
  // Use the SpeedProvider instance
  final SpeedProvider _speedProvider = SpeedProvider();

  bool isLocationServiceEnabled = true;
  bool isMeasurementActive = false;
  bool isMeasurementStarted = false;
  bool showMovementWarning = false;
  bool isTestButtonVisible = false;
  Timer? _speedIncreaseTimer;
  DateTime? _startTime;
  Timer? _measurementTimer;
  bool _waitingForSpeedToReachThreshold = false;
  bool isKmh = true; // Alapértelmezettként km/h-ban jelenik meg a sebesség

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    _listenToLocationServiceStatus();

    // Add listener to SpeedProvider to get updates
    _speedProvider.addListener(_onSpeedChanged);

    // Indítsa el automatikusan a mérést, amikor betöltődik az oldal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMeasurement();
    });
  }

  void _onSpeedChanged() {
    // This will be called whenever the speed changes in SpeedProvider

    // Csak akkor induljon el a mérés, ha a mérés aktív
    if (isMeasurementActive &&
        !_waitingForSpeedToReachThreshold &&
        _speedProvider.currentSpeed >= 3) {
      _waitingForSpeedToReachThreshold = true;
      _startMeasurementTimer();
    }

    // Force widget refresh
    if (mounted) {
      setState(() {});
    }
  }

  void _checkPermissionsAndStartListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _speedProvider.isLocationServiceEnabled = serviceEnabled;
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

    // Start tracking speed from the SpeedProvider
    _speedProvider.startSpeedTracking();
  }

  void _listenToLocationServiceStatus() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      bool isEnabled = status == ServiceStatus.enabled;
      setState(() {
        _speedProvider.isLocationServiceEnabled = isEnabled;
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

    _measurementTimer =
        Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      if (_speedProvider.currentSpeed >= 100) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  void _finishMeasurement() {
    if (_startTime != null && mounted) {
      // Add mounted check here
      final elapsedTime = DateTime.now().difference(_startTime!);
      showResultAndReturnToHomePage(
          context, elapsedTime, 100, _resetMeasurement);
    }
  }

  void _resetMeasurement() {
    if (!mounted) return; // Add early return if not mounted

    setState(() {
      isMeasurementActive = false;
      isMeasurementStarted = false;
      isTestButtonVisible = false;
      _waitingForSpeedToReachThreshold = false;
    });

    _measurementTimer?.cancel();
    _measurementTimer = null;

    // Only navigate if still mounted
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _startSpeedIncrease() {
    const double targetSpeed = 100.0;
    const Duration interval = Duration(milliseconds: 100);

    _speedIncreaseTimer = Timer.periodic(interval, (Timer timer) {
      // Update the speed in SpeedProvider for testing purposes
      _speedProvider
          .updateSpeed((_speedProvider.currentSpeed / 3.6) + (1.0 / 3.6));

      if (_speedProvider.currentSpeed >= targetSpeed) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  @override
  void dispose() {
    _speedIncreaseTimer?.cancel();
    _measurementTimer?.cancel();
    _speedProvider.removeListener(_onSpeedChanged);
    super.dispose();
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
                        width: MediaQuery.sizeOf(context).width * 1,
                        height: MediaQuery.sizeOf(context).width * 1,
                        child: GestureDetector(
                          onTap: _toggleSpeedUnit,
                          child: CustomPaint(
                            painter: MeterPainter(
                                _getSpeedInCurrentUnit(
                                    _speedProvider.currentSpeed),
                                isKmh: isKmh),
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
                ],
              )
            : const LocationDisabledScreen(),
      ),
    );
  }
}
