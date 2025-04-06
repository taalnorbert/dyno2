import 'dart:async';
import 'package:geolocator/geolocator.dart';

class SpeedService {
  double currentSpeed = 0.0; // Jelenlegi sebesség km/h-ban
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
  int _measurementType = 0; // 0: 0-100, 1: 100-200

  // Initializing and permission checks
  Future<void> checkPermissionsAndStartListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    isLocationServiceEnabled = serviceEnabled;

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

    // Start listening to position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(milliseconds: 100),
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      updateSpeed(position.speed);
    });
  }

  // Update current speed
  void updateSpeed(double speed) {
    double newSpeed = speed * 3.6; // m/s to km/h
    if (newSpeed != currentSpeed) {
      currentSpeed = newSpeed;
    }
  }

  // Reset speed measurement
  void resetMeasurement() {
    currentSpeed = 0.0;
    isMeasurementActive = false;
    isMeasurementStarted = false;
    showMovementWarning = false;
    showMovementTooHigh = false;
    showWarningMessage = false;
    isTestButtonVisible = false;
  }

  // Clean up
  void dispose() {
    _positionStreamSubscription?.cancel();
    _speedIncreaseTimer?.cancel();
    _measurementTimer?.cancel();
  }
}
