import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SpeedProvider extends ChangeNotifier {
  static final SpeedProvider _instance = SpeedProvider._internal();
  factory SpeedProvider() => _instance;
  SpeedProvider._internal();

  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  StreamSubscription<Position>? _positionStreamSubscription;

  void updateSpeed(double speed) {
    double newSpeed = speed * 3.6;
    if (newSpeed != currentSpeed) {
      currentSpeed = newSpeed;
      notifyListeners();
    }
  }

  void startSpeedTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: Duration(milliseconds: 100),
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      updateSpeed(position.speed);
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
