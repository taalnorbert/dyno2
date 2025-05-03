import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeedProvider extends ChangeNotifier {
  static final SpeedProvider _instance = SpeedProvider._internal();
  factory SpeedProvider() => _instance;

  static const String _speedUnitKey = 'speedUnit';
  bool _isKmh = true;

  SpeedProvider._internal() {
    _initializePreferences();
    _checkLocationService();
    _startLocationServiceListener();
  }

  Future<void> _initializePreferences() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await _loadSpeedUnit();
    } catch (e) {
      _isKmh = true; // Fallback to default
    }
  }

  double currentSpeed = 0.0;
  bool isLocationServiceEnabled = true;
  bool hasGpsSignal = false;

  bool get isKmh => _isKmh;

  Future<void> _loadSpeedUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isKmh = prefs.getBool(_speedUnitKey) ?? true;
      notifyListeners();
    } catch (e) {
      _isKmh = true; // Fallback to default
    }
  }

  Future<void> setSpeedUnit(bool value) async {
    _isKmh = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_speedUnitKey, value);
    notifyListeners();
  }

  // Helper methods for speed conversions
  double getSpeedInCurrentUnit(double speedInKmh) {
    return _isKmh ? speedInKmh : speedInKmh * 0.621371192;
  }

  double get firstTargetSpeed => _isKmh ? 100.0 : 60.0;
  double get secondTargetSpeed => _isKmh ? 200.0 : 120.0;

  double get firstMinThreshold => _isKmh ? 95.0 : 55.0;
  double get firstMaxThreshold => _isKmh ? 105.0 : 65.0;
  double get secondMinThreshold => _isKmh ? 195.0 : 115.0;
  double get secondMaxThreshold => _isKmh ? 205.0 : 125.0;

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

  // Módosított sebesség frissítés
  void updateSpeed(double speed) {
    // A speed m/s-ben érkezik, először mindig km/h-ra váltjuk
    double speedInKmh = speed * 3.6;

    if (speedInKmh != currentSpeed) {
      currentSpeed = speedInKmh;
      hasGpsSignal = true;
      notifyListeners();
    }
  }

  // Ez fogja visszaadni a sebességet az aktuális mértékegységben
  double getCurrentSpeed() {
    return _isKmh ? currentSpeed : currentSpeed * 0.621371192;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}
