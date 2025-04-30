import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SpeedProvider extends ChangeNotifier {
  static final SpeedProvider _instance = SpeedProvider._internal();
  factory SpeedProvider() => _instance;
  SpeedProvider._internal() {
    _checkLocationService();
    _startLocationServiceListener();
  }

  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  bool hasGpsSignal = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  Future<void> _checkLocationService() async {
    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();
    if (isLocationServiceEnabled) {
      startSpeedTracking();
    }
  }

  void _startLocationServiceListener() {
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) async {
        bool wasEnabled = isLocationServiceEnabled;
        isLocationServiceEnabled = (status == ServiceStatus.enabled);

        if (isLocationServiceEnabled && !wasEnabled) {
          // Ha épp most kapcsolták be
          await _checkLocationService();
        }
        notifyListeners();
      },
    );
  }

  void startSpeedTracking() {
    _positionStreamSubscription?.cancel(); // Előző stream leállítása ha volt

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: const Duration(milliseconds: 100),
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

  void updateSpeed(double speed) {
    double newSpeed = speed * 3.6;
    if (newSpeed != currentSpeed) {
      currentSpeed = newSpeed;
      hasGpsSignal = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}
