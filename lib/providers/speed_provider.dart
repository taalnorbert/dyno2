import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SpeedProvider extends ChangeNotifier {
  static final SpeedProvider _instance = SpeedProvider._internal();
  factory SpeedProvider() => _instance;
  SpeedProvider._internal();

  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  bool hasGpsSignal = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  DateTime? _lastUpdate;

  void updateSpeed(double speed) {
    double newSpeed = speed * 3.6;
    _lastUpdate = DateTime.now();

    if (newSpeed != currentSpeed) {
      currentSpeed = newSpeed;
      hasGpsSignal = true;
      notifyListeners();
    }
  }

  void startSpeedTracking() {
    // Start a timer to check GPS signal status
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_lastUpdate != null) {
        final difference = DateTime.now().difference(_lastUpdate!);
        if (difference.inSeconds >= 3) {
          hasGpsSignal = false;
          notifyListeners();
        }
      }
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: Duration(milliseconds: 100),
        distanceFilter: 0,
      ),
    ).listen(
      (Position position) {
        updateSpeed(position.speed);
      },
      onError: (error) {
        hasGpsSignal = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
