import 'dart:async';
import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../meter_painter.dart';
import '../../widgets/buttons/measurement_button.dart';
import '../../widgets/Messages/warning_message.dart';
import '../../widgets/Messages/success_message.dart';
import '../../widgets/Messages/result_dialog.dart';
import '../../../providers/speed_provider.dart';

class QuarterMile extends StatefulWidget {
  const QuarterMile({super.key});

  @override
  State<QuarterMile> createState() => _QuarterMileState();
}

class _QuarterMileState extends State<QuarterMile> {
  final SpeedProvider _speedProvider = SpeedProvider();
  double _distanceTraveled = 0.0;
  Position? _lastPosition;

  bool isLocationServiceEnabled = true;
  bool isMeasurementActive = false;
  bool isMeasurementStarted = false;
  bool showMovementWarning = false;
  bool isTestButtonVisible = false;
  bool _measurementTimerStarted = false;
  bool _isMeasurementFinished = false; // Add the flag to existing properties
  DateTime? _startTime;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Get quarter mile distance based on unit
  double get quarterMileDistance => _speedProvider.isKmh ? 0.402336 : 0.25;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    // Add listener for speed changes
    _speedProvider.addListener(_onSpeedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMeasurement();
    });
  }

  void _onSpeedChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _checkPermissionsAndStartListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _speedProvider.isLocationServiceEnabled = serviceEnabled;
    });

    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Connect the position stream to _updatePosition
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: Duration(milliseconds: 100),
        distanceFilter: 0,
      ),
    ).listen(
        _updatePosition); // Add this line to connect the stream to _updatePosition
  }

  void _updatePosition(Position newPosition) {
    if (_lastPosition != null && isMeasurementActive) {
      final double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      _distanceTraveled += distance / 1000; // Convert to kilometers

      // Start timer after 5 meters (0.005 km)
      if (!_measurementTimerStarted && _distanceTraveled >= 0.005) {
        _measurementTimerStarted = true;
        _startTime = DateTime.now();
        setState(() {
          isMeasurementStarted = true;
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

      // Check if quarter mile reached
      if (_distanceTraveled >= quarterMileDistance) {
        _finishMeasurement();
      }
    }
    _lastPosition = newPosition;
  }

  void _startMeasurement() {
    if (_speedProvider.getCurrentSpeed() > 5.0) {
      setState(() {
        showMovementWarning = true;
      });
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showMovementWarning = false;
          });
        }
      });
      return;
    }

    setState(() {
      isMeasurementActive = true;
      isMeasurementStarted = true; // Add this line to show success message
      _measurementTimerStarted = false;
      _distanceTraveled = 0.0;
      _startTime = null;
      _isMeasurementFinished =
          false; // Reset flag when starting new measurement
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

  void _finishMeasurement() {
    if (_startTime != null && mounted && !_isMeasurementFinished) {
      _isMeasurementFinished = true; // Set flag to prevent multiple saves

      // Cancel subscription
      _positionStreamSubscription?.cancel();

      final elapsedTime = DateTime.now().difference(_startTime!);
      final timeInSeconds = elapsedTime.inMilliseconds / 1000.0;

      // Save measurement to database
      AuthService().saveMeasurement('quarter-mile', timeInSeconds).then((_) {
        if (!mounted) return;

        // Reset measurement state
        setState(() {
          isMeasurementActive = false;
          _measurementTimerStarted = false;
          isTestButtonVisible = false;
          _distanceTraveled = 0.0;
          _lastPosition = null;
        });

        // Check mounted again before showing dialog
        if (mounted) {
          showResultAndReturnToHomePage(
            context,
            elapsedTime,
            (_speedProvider.isKmh ? 402.336 : 402.336).toInt(),
            () {
              if (mounted) {
                context.go('/home');
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
            (_speedProvider.isKmh ? 402.336 : 402.336).toInt(),
            () {
              if (mounted) {
                context.go('/home');
              }
            },
          );
        }
      });
    }
  }

  void _resetMeasurement() {
    setState(() {
      isMeasurementActive = false;
      isMeasurementStarted = false;
      isTestButtonVisible = false;
      _measurementTimerStarted = false;
      _distanceTraveled = 0.0;
      _lastPosition = null;
      _startTime = null;
      _isMeasurementFinished = false; // Reset the flag
    });

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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
                      _speedProvider.getCurrentSpeed(),
                      isKmh: _speedProvider.isKmh,
                    ),
                  ),
                ),
                if (isMeasurementActive) ...[
                  NoOutlineMeasurementButton(
                    onPressed: _resetMeasurement,
                    text: "Cancel",
                    backgroundColor: Colors.red,
                  ),
                ],
              ],
            ),
            if (isMeasurementStarted)
              SuccessMessage(
                message: "Measurement started!",
                icon: Icons.check,
                color: Color(0xFF0ca644),
                iconColor: Color(0xFF84D65A),
              ),
            if (showMovementWarning)
              WarningMessage(
                message: "Vehicle is moving!",
                icon: Icons.warning,
                color: Colors.orange,
                iconColor: Colors.yellow,
              ),
          ],
        ),
      ),
    );
  }
}
