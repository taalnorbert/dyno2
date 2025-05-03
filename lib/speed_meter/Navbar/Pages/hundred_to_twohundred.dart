import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/buttons/measurement_button.dart';
import '../../meter_painter.dart';
import '../../widgets/Messages/warning_message.dart';
import '../../widgets/Messages/success_message.dart';
import '../../widgets/Messages/result_dialog.dart';
import '../../../providers/speed_provider.dart';

class HundredToTwoHundred extends StatefulWidget {
  const HundredToTwoHundred({super.key});

  @override
  State<HundredToTwoHundred> createState() => _HundredToTwoHundredState();
}

class _HundredToTwoHundredState extends State<HundredToTwoHundred> {
  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  bool isMeasurementActive = false;
  bool isMeasurementStarted = false;
  bool showMovementWarning = false;
  bool showMovementTooHigh = false;
  bool isTestButtonVisible = false;
  Timer? _speedIncreaseTimer;
  DateTime? _startTime;
  Timer? _measurementTimer;
  bool _waitingForSpeedToReachThreshold = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  final SpeedProvider _speedProvider = SpeedProvider();

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    _listenToLocationServiceStatus();
    // Indítsa el automatikusan a mérést, amikor betöltődik az oldal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMeasurement();
    });
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

  double _getSpeedInCurrentUnit(double speed) {
    return _speedProvider.isKmh ? speed : speed * 0.621371192;
  }

  void _updateSpeed(double speed) {
    // Convert speed from m/s to km/h
    double speedKmh = speed * 3.6;

    // Only start timer if measurement is active and we reach the threshold
    if (isMeasurementActive &&
        !_waitingForSpeedToReachThreshold &&
        speedKmh >= (_speedProvider.isKmh ? 100.0 : 60.0)) {
      _waitingForSpeedToReachThreshold = true;
      _startMeasurementTimer();
    }

    // Show warning if speed is too high at start
    setState(() {
      showMovementTooHigh = speedKmh >= (_speedProvider.isKmh ? 100.0 : 60.0);
    });
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
    // Check if speed is too high to start
    double currentSpeedKmh = _speedProvider.getCurrentSpeed();
    if (currentSpeedKmh >= (_speedProvider.isKmh ? 100.0 : 60.0)) {
      setState(() {
        showMovementTooHigh = true;
      });

      // Hide warning after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showMovementTooHigh = false;
          });
        }
      });
      return;
    }

    // Start measurement if speed is acceptable
    setState(() {
      isMeasurementActive = true;
      isMeasurementStarted = true;
      isTestButtonVisible = true;
      _waitingForSpeedToReachThreshold = false;
      showMovementTooHigh = false;
    });

    // Hide "Measurement started" message after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isMeasurementStarted = false;
        });
      }
    });
  }

  void _startMeasurementTimer() {
    setState(() {
      _startTime = DateTime.now();
    });

    _measurementTimer =
        Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      double targetSpeed = _speedProvider.secondTargetSpeed;
      if (_speedProvider.getCurrentSpeed() >= targetSpeed) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  void _finishMeasurement() {
    if (_startTime != null) {
      final elapsedTime = DateTime.now().difference(_startTime!);
      showResultAndReturnToHomePage(
          context, elapsedTime, 200, _resetMeasurement);
    }
  }

  void _resetMeasurement() {
    setState(() {
      isMeasurementActive = false;
      isMeasurementStarted = false;
      isTestButtonVisible = false;
      _waitingForSpeedToReachThreshold = false;
      currentSpeed = 0.0;
    });

    _measurementTimer?.cancel();
    _measurementTimer = null;

    // Opcionálisan visszatérés a Home oldalra
    Navigator.pop(context);
  }

  void _startSpeedIncrease() {
    // 100-200 mérésnél 100 km/h-tól indulunk
    setState(() {
      currentSpeed = 103.0;
    });

    const double targetSpeed = 200.0;
    const Duration interval = Duration(milliseconds: 100);

    _speedIncreaseTimer = Timer.periodic(interval, (Timer timer) {
      setState(() {
        if (currentSpeed < targetSpeed) {
          currentSpeed += 1.0;
        } else {
          timer.cancel();
          _finishMeasurement();
        }
      });
    });
  }

  @override
  void dispose() {
    _speedIncreaseTimer?.cancel();
    _measurementTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
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
                  width: MediaQuery.sizeOf(context).width * 1,
                  height: MediaQuery.sizeOf(context).width * 1,
                  child: CustomPaint(
                    painter: MeterPainter(_getSpeedInCurrentUnit(currentSpeed),
                        isKmh: _speedProvider.isKmh),
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
          ],
        ),
      ),
    );
  }
}
