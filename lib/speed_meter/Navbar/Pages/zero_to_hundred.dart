import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../meter_painter.dart';
import '../../widgets/buttons/measurement_button.dart';
import '../../widgets/Messages/warning_message.dart';
import '../../widgets/Messages/success_message.dart';
import '../../widgets/Messages/result_dialog.dart';
import '../../../providers/speed_provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

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
  bool _isMeasurementFinished = false; // Add this flag

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

  double _getSpeedInCurrentUnit(double speed) {
    return _speedProvider.getSpeedInCurrentUnit(speed);
  }

  void _startMeasurement() {
    setState(() {
      isMeasurementActive = true;
      isMeasurementStarted = true;
      isTestButtonVisible = true;
      _waitingForSpeedToReachThreshold = false;
      _isMeasurementFinished =
          false; // Reset the flag when starting new measurement
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
      if (_speedProvider.getCurrentSpeed() >= _speedProvider.firstTargetSpeed) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  void _finishMeasurement() {
    // Check if measurement is already finished
    if (_startTime != null && mounted && !_isMeasurementFinished) {
      // Set flag to prevent multiple saves
      _isMeasurementFinished = true;

      // Cancel all timers first
      _measurementTimer?.cancel();
      _speedIncreaseTimer?.cancel();

      final elapsedTime = DateTime.now().difference(_startTime!);
      final timeInSeconds = elapsedTime.inMilliseconds / 1000.0;

      // Save measurement to database
      AuthService().saveMeasurement('zero-to-hundred', timeInSeconds).then((_) {
        if (!mounted) return;

        // Reset measurement state
        setState(() {
          isMeasurementActive = false;
          _waitingForSpeedToReachThreshold = false;
          isTestButtonVisible = false;
        });

        // Show result and return to home
        if (mounted) {
          showResultAndReturnToHomePage(
            context,
            elapsedTime,
            _speedProvider.firstTargetSpeed.toInt(),
            () {
              if (mounted) {
                context.pop(); // Visszamegy az előző oldalra
              }
            },
          );
        }
      }).catchError((error) {
        // ignore: avoid_print
        print('Error saving measurement: $error');
        if (mounted) {
          showResultAndReturnToHomePage(
            context,
            elapsedTime,
            _speedProvider.firstTargetSpeed.toInt(),
            () {
              if (mounted) {
                context.pop(); // Visszamegy az előző oldalra
              }
            },
          );
        }
      });
    }
  }

  void _resetMeasurement() {
    if (!mounted) return;

    setState(() {
      isMeasurementActive = false;
      isMeasurementStarted = false;
      isTestButtonVisible = false;
      _waitingForSpeedToReachThreshold = false;
      _isMeasurementFinished = false; // Reset the flag
    });

    _measurementTimer?.cancel();
    _measurementTimer = null;

    // Replace Navigator.pop with context.pop
    if (mounted) {
      context.pop(); // Visszamegy az előző oldalra go_router helyett
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
                    painter: MeterPainter(
                        _getSpeedInCurrentUnit(_speedProvider.currentSpeed),
                        isKmh: _speedProvider.isKmh),
                  ),
                ),
                if (isMeasurementActive) ...[
                  NoOutlineMeasurementButton(
                    onPressed: _resetMeasurement,
                    text: AppLocalizations.cancel,
                    backgroundColor: Colors.red,
                  ),
                  if (isTestButtonVisible)
                    NoOutlineMeasurementButton(
                      onPressed: _startSpeedIncrease,
                      text: AppLocalizations.testSpeedIncrease,
                      backgroundColor: Colors.blue,
                    ),
                ],
              ],
            ),
            if (isMeasurementStarted)
              SuccessMessage(
                message: AppLocalizations.measurementStarted,
                icon: Icons.check,
                color: Color(0xFF0ca644),
                iconColor: Color(0xFF84D65A),
              ),
            if (showMovementWarning)
              WarningMessage(
                message: AppLocalizations.vehicleIsMoving,
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
