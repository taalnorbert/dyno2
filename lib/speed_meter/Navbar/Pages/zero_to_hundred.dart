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

class _ZeroToHundredState extends State<ZeroToHundred>
    with SingleTickerProviderStateMixin {
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
  bool _isMeasurementFinished = false;
  bool _isSpeedometerExpanded =
      false; // New variable for speedometer size animation

  late AnimationController _messageAnimationController;
  late Animation<Offset> _messageSlideAnimation;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
    _listenToLocationServiceStatus();

    // Initialize animation controller for message
    _messageAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    // Create slide animation that moves from top (-1.0) to its normal position (0.0)
    _messageSlideAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeOut,
    ));

    // Add listener to SpeedProvider to get updates
    _speedProvider.addListener(_onSpeedChanged);

    // Start measurement automatically when page loads
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
      isMeasurementStarted = true;
      isTestButtonVisible = true;
      _waitingForSpeedToReachThreshold = false;
      _isMeasurementFinished = false;
      _isSpeedometerExpanded = true; // Trigger speedometer animation
    });

    // Start the message slide animation
    _messageAnimationController.forward();

    // Make sure all Future.delayed callbacks check mounted status
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
      _isMeasurementFinished = false;
      _isSpeedometerExpanded = false; // Reset speedometer size
    });

    _measurementTimer?.cancel();
    _measurementTimer = null;
    _messageAnimationController.reset();

    // Replace Navigator.pop with context.pop
    if (mounted) {
      context.pop();
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
    _messageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center, // Center all children in the stack
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use AnimatedScale instead of AnimatedContainer for proper proportional scaling
                AnimatedScale(
                  scale: _isSpeedometerExpanded
                      ? 1.1
                      : 1.0, // 10% larger when expanded
                  duration: Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width, // Keep it square
                    child: CustomPaint(
                      painter: MeterPainter(
                        _getSpeedInCurrentUnit(_speedProvider.currentSpeed),
                        isKmh: _speedProvider.isKmh,
                      ),
                    ),
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
            // Position the message at the top with proper centering
            if (isMeasurementStarted)
              Positioned(
                top: 50, // Adjust this value as needed for proper positioning
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _messageSlideAnimation,
                  child: Center(
                    // Center horizontally
                    child: SuccessMessage(
                      message: AppLocalizations.measurementStarted,
                      icon: Icons.check,
                      color: Color(0xFF0ca644),
                      iconColor: Color(0xFF84D65A),
                    ),
                  ),
                ),
              ),
            if (showMovementWarning)
              Positioned(
                top: 50, // Match the same positioning as the success message
                left: 0,
                right: 0,
                child: Center(
                  // Center horizontally
                  child: WarningMessage(
                    message: AppLocalizations.vehicleIsMoving,
                    icon: Icons.warning,
                    color: Colors.orange,
                    iconColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
