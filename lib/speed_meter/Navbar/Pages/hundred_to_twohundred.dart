import 'dart:async';
import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/buttons/measurement_button.dart';
import '../../meter_painter.dart';
import '../../widgets/Messages/warning_message.dart';
import '../../widgets/Messages/success_message.dart';
import '../../widgets/Messages/result_dialog.dart';
import '../../../providers/speed_provider.dart';
import '../../../localization/app_localizations.dart';

class HundredToTwoHundred extends StatefulWidget {
  const HundredToTwoHundred({super.key});

  @override
  State<HundredToTwoHundred> createState() => _HundredToTwoHundredState();
}

class _HundredToTwoHundredState extends State<HundredToTwoHundred>
    with SingleTickerProviderStateMixin {
  final SpeedProvider _speedProvider = SpeedProvider();

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
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  bool _isMeasurementFinished = false;

  // Animation variables
  bool _isSpeedometerExpanded = false;
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

    // Only start timer if measurement is active and we reach the threshold
    if (isMeasurementActive &&
        !_waitingForSpeedToReachThreshold &&
        _speedProvider.getCurrentSpeed() >=
            (_speedProvider.isKmh ? 105.0 : 65.0)) {
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
    _serviceStatusSubscription =
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
      _isMeasurementFinished = false;
      _isSpeedometerExpanded = true; // Trigger speedometer animation
    });

    // Start the message slide animation
    _messageAnimationController.forward();

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
    if (_startTime != null && mounted && !_isMeasurementFinished) {
      _isMeasurementFinished = true; // Set flag to prevent multiple saves

      // Cancel all timers first
      _measurementTimer?.cancel();
      _speedIncreaseTimer?.cancel();

      final elapsedTime = DateTime.now().difference(_startTime!);
      final timeInSeconds = elapsedTime.inMilliseconds / 1000.0;

      // Save measurement to database
      AuthService()
          .saveMeasurement('hundred-to-twohundred', timeInSeconds)
          .then((_) {
        if (!mounted) return;

        // Reset measurement state
        setState(() {
          isMeasurementActive = false;
          _waitingForSpeedToReachThreshold = false;
          isTestButtonVisible = false;
        });

        // Check mounted again before showing dialog
        if (mounted) {
          showResultAndReturnToHomePage(
            context,
            elapsedTime,
            _speedProvider.secondTargetSpeed.toInt(),
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
            _speedProvider.secondTargetSpeed.toInt(),
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

    // Visszamegy az előző oldalra
    if (mounted) {
      context.pop();
    }
  }

  void _startSpeedIncrease() {
    const double targetSpeed = 200.0;
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
    _serviceStatusSubscription?.cancel();
    _speedProvider.removeListener(_onSpeedChanged);
    _messageAnimationController.dispose(); // Dispose animation controller
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
                // Use AnimatedScale for proper proportional scaling
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
                        _speedProvider.getCurrentSpeed(),
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
              WarningMessage(
                message: AppLocalizations.vehicleIsMoving,
                icon: Icons.warning,
                color: Colors.orange,
                iconColor: Colors.white,
              ),
            if (showMovementTooHigh)
              WarningMessage(
                message: "A sebesség túl magas!",
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
