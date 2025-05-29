// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' show min, max, sqrt, cos, pi;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

// LatLng osztály hozzáadása, amely nincs a kapott kódban
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class LapTimeScreen extends StatefulWidget {
  const LapTimeScreen({super.key});

  @override
  State<LapTimeScreen> createState() => _LapTimeScreenState();
}

class _LapTimeScreenState extends State<LapTimeScreen>
    with SingleTickerProviderStateMixin {
  final List<LatLng> _trackPoints = []; // Rögzített pálya pontjai
  LatLng? _startPoint; // Rajtvonal pozíciója
  LatLng? _currentPosition; // Jelenlegi pozíció
  bool _isRecording = false; // Pálya rögzítés alatt áll-e
  bool _canComplete = false; // Befejezhető-e a rögzítés
  bool _trackCompleted = false; // Pálya rögzítése befejezve
  StreamSubscription<Position>? _positionStreamSubscription;
  final int _minPointsForCompletion = 30; // Minimális pontszám a befejezéshez
// Befejezési távolság a startponttól (méterben)
  final Duration _minRecordingTime =
      Duration(seconds: 10); // Minimális rögzítési idő
  DateTime? _recordingStartTime;
  DateTime? _trackCompletionTime;

  // Lap időmérés változók
  int _lapCount = 0;
  final List<Duration> _lapTimes = [];
  DateTime? _currentLapStartTime;

  // Animáció vezérlő
  late AnimationController _pulseAnimationController;

  // Design konstans színek
  final Color _primaryRed = Color(0xFFE71D36);
  final Color _darkerRed = Color(0xFFC41426);
  final Color _backgroundBlack = Color(0xFF121212);
  final Color _cardBlack = Color(0xFF1E1E1E);
  final Color _accentGrey = Color(0xFF333333);
  final Color _textWhite = Color(0xFFF5F5F5);
  final Color _highlightYellow = Color(0xFFFFD23F);

  // Define the start/finish line as a vector
  LatLng? _startLinePoint1;
  LatLng? _startLinePoint2;

  // Add these fields
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  bool _isGpsAccurate = false;

  @override
  void initState() {
    super.initState();

    // Inicializáljuk az animáció vezérlőt
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Beállítjuk a rendszer UI-t is fekete-piros stílusra
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _backgroundBlack,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Kérjük a helymeghatározás jogosultságokat
    _requestLocationPermission();

    // Initialize sensors
    _initSensors();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pulseAnimationController.dispose();

    // Cancel sensor subscriptions
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();

    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Ellenőrizzük, hogy a helymeghatározási szolgáltatás be van-e kapcsolva
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // A helymeghatározási szolgáltatás nincs bekapcsolva, megjelenítünk egy üzenetet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('A helymeghatározási szolgáltatás nincs bekapcsolva.'),
            backgroundColor: _primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Ellenőrizzük a helymeghatározási engedélyeket
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Az engedélyt elutasították, megjelenítünk egy üzenetet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'A helymeghatározási engedély szükséges a pálya rögzítéséhez.'),
              backgroundColor: _primaryRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Az engedély véglegesen elutasítva, megjelenítünk egy üzenetet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'A helymeghatározási engedély véglegesen elutasítva. Engedélyezze a beállításokban.'),
            backgroundColor: _primaryRed,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Minden rendben, elindítjuk a pozíció követését
    _startPositionTracking();
  }

  void _startPositionTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      // Check position accuracy
      bool isAccurate =
          position.accuracy < 10.0; // 10 meters accuracy threshold
      setState(() {
        _isGpsAccurate = isAccurate;
      });

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // Apply simple Kalman filtering if GPS is inaccurate
      if (!isAccurate && _currentPosition != null) {
        // Simple position smoothing - weight between last known position and new position
        newPosition = LatLng(
            _currentPosition!.latitude * 0.7 + newPosition.latitude * 0.3,
            _currentPosition!.longitude * 0.7 + newPosition.longitude * 0.3);
      }

      // Store previous position for line crossing detection
      LatLng? prevPosition = _currentPosition;

      setState(() {
        _currentPosition = newPosition;

        // If recording, add the point to the track
        if (_isRecording) {
          _trackPoints.add(newPosition);

          // Check if the track can be completed
          if (_canComplete &&
              _trackPoints.length > _minPointsForCompletion &&
              _startLinePoint1 != null &&
              _startLinePoint2 != null &&
              prevPosition != null &&
              _hasLineCrossing(prevPosition, newPosition)) {
            _completeTrackRecording();
          }
        }
        // For lap timing when track is already recorded
        else if (_trackCompleted &&
            _startLinePoint1 != null &&
            _startLinePoint2 != null &&
            prevPosition != null &&
            _hasLineCrossing(prevPosition, newPosition)) {
          _onLapCompleted();
        }
      });
    });
  }

  void _startRecording() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Várakozás a pontos helymeghatározásra...'),
          backgroundColor: _primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set the initial position as the start point
    setState(() {
      _startPoint = _currentPosition;
      _trackPoints.clear();
      _trackPoints.add(_startPoint!);
      _isRecording = true;
      _canComplete = false;
      _trackCompleted = false;
      _recordingStartTime = DateTime.now();
      _currentLapStartTime = DateTime.now();
      _lapTimes.clear();
      _lapCount = 0;
    });

    // Wait for a few points to determine direction and set up finish line
    Future.delayed(Duration(seconds: 3), () {
      if (_trackPoints.length > 10) {
        // Determine initial direction from first few points
        LatLng initialDirection =
            _calculateDirection(_trackPoints.sublist(0, 10));

        // Create a perpendicular line segment for the start/finish line
        // This makes a line perpendicular to the track's direction
        _startLinePoint1 =
            _createOffsetPoint(_startPoint!, initialDirection, 10, true);
        _startLinePoint2 =
            _createOffsetPoint(_startPoint!, initialDirection, 10, false);
      } else {
        // Fallback if not enough points
        _startLinePoint1 = _startPoint;
        _startLinePoint2 = _startPoint;
      }
    });

    // Engedélyezzük a befejezést a minimális idő után
    Future.delayed(_minRecordingTime, () {
      if (_isRecording && mounted) {
        setState(() {
          _canComplete = true;
        });
      }
    });
  }

  void _completeTrackRecording() {
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
      _trackCompleted = true;
      _trackCompletionTime = DateTime.now();
      _currentLapStartTime = DateTime.now(); // Új kör kezdése
    });

    // Kör befejezése értesítés
    _showTrackCompletionDialog();
  }

  void _resetTracking() {
    setState(() {
      _trackPoints.clear();
      _startPoint = null;
      _isRecording = false;
      _canComplete = false;
      _trackCompleted = false;
      _recordingStartTime = null;
      _trackCompletionTime = null;
      _currentLapStartTime = null;
      _lapTimes.clear();
      _lapCount = 0;
    });
  }

  void _onLapCompleted() {
    if (_currentLapStartTime == null) return;

    final now = DateTime.now();
    final lapTime = now.difference(_currentLapStartTime!);

    setState(() {
      _lapCount++;
      _lapTimes.add(lapTime);
      _currentLapStartTime = now; // Új kör kezdése
    });

    // Értesítés az új körről
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kör #$_lapCount: ${_formatDuration(lapTime)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _highlightYellow,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTrackCompletionDialog() {
    final recordingDuration =
        _trackCompletionTime!.difference(_recordingStartTime!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _primaryRed, width: 2),
        ),
        title: Text(
          'Pálya rögzítve!',
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A pálya sikeresen rögzítve.',
              style: TextStyle(color: _textWhite),
            ),
            SizedBox(height: 12),
            _infoRow('Pontok száma:', '${_trackPoints.length}'),
            _infoRow('Rögzítési idő:', _formatDuration(recordingDuration)),
            SizedBox(height: 8),
            Text(
              'Most köridőket mérhetsz a pályán!',
              style: TextStyle(
                color: _highlightYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _primaryRed,
            ),
            child: Text('RENDBEN'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: _textWhite.withOpacity(0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  String _getStatusText() {
    if (_trackCompleted) {
      return "Pálya kész - Köridő követés aktív";
    } else if (!_isRecording) {
      return "Nincs aktív rögzítés";
    } else if (!_canComplete) {
      int secondsRemaining = _minRecordingTime.inSeconds -
          DateTime.now()
              .difference(_recordingStartTime ?? DateTime.now())
              .inSeconds;
      return "Rögzítés... (${secondsRemaining > 0 ? 'Még $secondsRemaining mp' : 'Hamarosan körbeérhet'})";
    } else {
      return "Visszatérhet a startponthoz";
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));

    return '$minutes:$seconds.$milliseconds';
  }

  // A pálya rajzolásához használt színek
  Color _getStatusBarColor() {
    if (_trackCompleted) return _highlightYellow.withOpacity(0.1);
    if (_isRecording) return _primaryRed.withOpacity(0.1);
    return _accentGrey.withOpacity(0.1);
  }

  Color _getStatusTextColor() {
    if (_trackCompleted) return _highlightYellow;
    if (_isRecording) return _primaryRed;
    return _textWhite;
  }

  Color _getTrackBorderColor() {
    if (_trackCompleted) return _highlightYellow;
    if (_isRecording) return _primaryRed;
    return _accentGrey;
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isActive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? backgroundColor
            : (onPressed == null
                ? _accentGrey.withOpacity(0.3)
                : backgroundColor),
        foregroundColor: foregroundColor,
        disabledForegroundColor: _textWhite.withOpacity(0.5),
        disabledBackgroundColor: _accentGrey.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSaveButton({
    required VoidCallback? onPressed,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.save_alt),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryRed,
        side: BorderSide(
            color:
                onPressed == null ? _accentGrey.withOpacity(0.3) : _primaryRed),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _initSensors() {
    // Listen to accelerometer
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
      });
    });

    // Listen to gyroscope
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
      });
    });

    // Listen to magnetometer
    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the animation controller is initialized before building the UI
    if (!_pulseAnimationController.isAnimating) {
      _pulseAnimationController.repeat(reverse: true);
    }

    return Scaffold(
      backgroundColor: _backgroundBlack,
      appBar: AppBar(
        title: Text(_trackCompleted ? "KÖRIDŐMÉRÉS" : "PÁLYARÖGZÍTÉS",
            style: TextStyle(
              color: _textWhite,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )),
        backgroundColor: _cardBlack,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_trackCompleted || _trackPoints.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh, color: _textWhite),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: _cardBlack,
                    title:
                        Text('Újrakezdés', style: TextStyle(color: _textWhite)),
                    content: Text(
                        'Biztosan törölni szeretnéd a jelenlegi pályát és az adatokat?',
                        style: TextStyle(color: _textWhite.withOpacity(0.8))),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:
                            Text('MÉGSE', style: TextStyle(color: _textWhite)),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetTracking();
                          Navigator.pop(context);
                        },
                        child:
                            Text('IGEN', style: TextStyle(color: _primaryRed)),
                      ),
                    ],
                  ),
                );
              },
            )
        ],
      ),
      body: Column(
        children: [
          // Státusz kijelző és lap számláló
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _getStatusBarColor(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Státusz szöveg
                Row(
                  children: [
                    if (_isRecording || _trackCompleted)
                      AnimatedBuilder(
                        animation: _pulseAnimationController,
                        builder: (context, child) {
                          return Container(
                            width: 12,
                            height: 12,
                            margin: EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_isRecording
                                      ? _primaryRed
                                      : _highlightYellow)
                                  .withOpacity(0.5 +
                                      0.5 * _pulseAnimationController.value),
                            ),
                          );
                        },
                      ),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusTextColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Köridő számláló
                if (_trackCompleted && _lapCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _highlightYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _highlightYellow.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Kör #$_lapCount',
                      style: TextStyle(
                        color: _highlightYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Pálya megjelenítés
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBlack,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getTrackBorderColor().withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: _getTrackBorderColor().withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: ModernTrackPainter(
                        trackPoints: _trackPoints,
                        currentPosition: _currentPosition,
                        startPoint: _startPoint,
                        startLinePoint1: _startLinePoint1,
                        startLinePoint2: _startLinePoint2,
                        trackColor: _primaryRed,
                        positionColor: _highlightYellow,
                        gridColor: _accentGrey.withOpacity(0.2),
                        trackCompleted: _trackCompleted,
                        isGpsAccurate: _isGpsAccurate,
                      ),
                      size: Size.infinite,
                    ),

                    // Információs panel alul
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _cardBlack.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _accentGrey.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Pontok száma",
                                      style: TextStyle(
                                        color: _textWhite.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "${_trackPoints.length}",
                                      style: TextStyle(
                                        color: _textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                if (_canComplete && _isRecording)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _primaryRed.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: _primaryRed.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.flag,
                                            color: _primaryRed, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          "Kész a kör",
                                          style: TextStyle(
                                            color: _primaryRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Aktuális köridő kijelzése
                                if (_trackCompleted &&
                                    _currentLapStartTime != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Aktuális köridő",
                                        style: TextStyle(
                                          color: _textWhite.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _formatDuration(DateTime.now()
                                            .difference(_currentLapStartTime!)),
                                        style: TextStyle(
                                          color: _highlightYellow,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            // Legjobb köridő kijelzése
                            if (_trackCompleted && _lapTimes.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _highlightYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _highlightYellow.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined,
                                            color: _highlightYellow, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          "Legjobb köridő",
                                          style: TextStyle(
                                            color: _highlightYellow,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatDuration(_lapTimes
                                          .reduce((a, b) => a < b ? a : b)),
                                      style: TextStyle(
                                        color: _textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Vezérlőgombok
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_trackCompleted)
                    // Rögzítés vezérlők
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildControlButton(
                            icon: Icons.play_arrow_rounded,
                            label: "INDÍTÁS",
                            onPressed: _isRecording ? null : _startRecording,
                            backgroundColor: _primaryRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildControlButton(
                            icon: Icons.stop_rounded,
                            label: "BEFEJEZÉS",
                            onPressed: (_isRecording && _canComplete)
                                ? _completeTrackRecording
                                : null,
                            backgroundColor: _accentGrey,
                            foregroundColor: Colors.white,
                            isActive: _isRecording,
                          ),
                        ),
                      ],
                    )
                  else
                    // Köridő vezérlők
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Köridők részletes nézete
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: _cardBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                builder: (context) => _buildLapTimesSheet(),
                              );
                            },
                            icon: Icon(Icons.list_alt),
                            label: Text("KÖRIDŐK RÉSZLETEI"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _highlightYellow,
                              foregroundColor: _backgroundBlack,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _buildSaveButton(
                    onPressed: (_trackCompleted ||
                            (_trackPoints.isNotEmpty && !_isRecording))
                        ? () {
                            // Itt lehet menteni a pályát pl. fájlba vagy adatbázisba
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pálya és köridők mentve!'),
                                backgroundColor: _darkerRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        : null,
                    label: "MENTÉS",
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildLapTimesSheet() {
    // A köridők üres lista, ha nincs még kör
    if (_lapTimes.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_off_outlined,
                color: _accentGrey,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Nincs még rögzített köridő',
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Haladj át a rajtvonalon az első köridő rögzítéséhez!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textWhite.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Megkeressük a legjobb köridőt
    Duration bestLapTime = _lapTimes.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: _highlightYellow),
              SizedBox(width: 8),
              Text(
                'Köridők',
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Text(
                'Összesen: $_lapCount kör',
                style: TextStyle(
                  color: _textWhite.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Legjobb köridő kártya
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _highlightYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _highlightYellow),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _highlightYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.emoji_events,
                      color: _backgroundBlack,
                      size: 28,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legjobb köridő',
                      style: TextStyle(
                        color: _highlightYellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatDuration(bestLapTime),
                      style: TextStyle(
                        color: _textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Kör #${_lapTimes.indexOf(bestLapTime) + 1}',
                      style: TextStyle(
                        color: _textWhite.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Köridők lista
          Expanded(
            child: ListView.builder(
              itemCount: _lapTimes.length,
              itemBuilder: (context, index) {
                final lapNumber = index + 1;
                final lapTime = _lapTimes[index];
                final isFirstLap = index == 0;
                final isLastLap = index == _lapTimes.length - 1;
                final isBestLap = lapTime == bestLapTime;

                // Különbség az előző köridőhöz képest
                String difference = '';
                if (!isFirstLap) {
                  final prevLapTime = _lapTimes[index - 1];
                  final diff =
                      lapTime.inMilliseconds - prevLapTime.inMilliseconds;
                  final sign = diff > 0 ? '+' : '';
                  difference =
                      '$sign${_formatDuration(Duration(milliseconds: diff.abs()))}';
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isBestLap
                        ? _highlightYellow.withOpacity(0.1)
                        : _accentGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBestLap
                          ? _highlightYellow.withOpacity(0.5)
                          : _accentGrey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Kör száma
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isBestLap ? _highlightYellow : _accentGrey,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            lapNumber.toString(),
                            style: TextStyle(
                              color: isBestLap ? _backgroundBlack : _textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Köridő adatok
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(lapTime),
                                  style: TextStyle(
                                    color: _textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (!isFirstLap)
                                  Text(
                                    difference,
                                    style: TextStyle(
                                      color: difference.startsWith('+')
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              isLastLap
                                  ? 'Legutóbbi kör'
                                  : (isBestLap
                                      ? 'Legjobb köridő'
                                      : 'Kör #$lapNumber'),
                              style: TextStyle(
                                color: isBestLap
                                    ? _highlightYellow
                                    : _textWhite.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Calculate direction from a list of points
LatLng _calculateDirection(List<LatLng> points) {
  if (points.length < 2) return points.first;

  return LatLng(points.last.latitude - points.first.latitude,
      points.last.longitude - points.first.longitude);
}

// Create points perpendicular to direction of travel
LatLng _createOffsetPoint(
    LatLng center, LatLng direction, double meters, bool isLeft) {
  // Calculate perpendicular vector
  double dx = direction.longitude - center.longitude;
  double dy = direction.latitude - center.latitude;

  // Normalize and rotate 90 degrees
  double length = sqrt(dx * dx + dy * dy);
  dx = dx / length;
  dy = dy / length;

  double perpDx = isLeft ? -dy : dy;
  double perpDy = isLeft ? dx : -dx;

  // Convert meters to appropriate coordinate units (approximate)
  double metersToDegreesLat = 1.0 / 111111.0; // 1 meter in degrees latitude
  double metersToDegreesLng = 1.0 /
      (111111.0 *
          cos(center.latitude * (pi / 180.0))); // 1 meter in degrees longitude

  return LatLng(center.latitude + (perpDy * meters * metersToDegreesLat),
      center.longitude + (perpDx * meters * metersToDegreesLng));
}

// Line crossing detection
bool _hasLineCrossing(LatLng prevPosition, LatLng currentPosition) {
  return _doLineSegmentsIntersect(
      prevPosition, currentPosition, _startLinePoint1 as LatLng, _startLinePoint2 as LatLng);
}

// ignore: camel_case_types
class _startLinePoint2 {
}

// ignore: camel_case_types
class _startLinePoint1 {
}

// Line intersection algorithm
bool _doLineSegmentsIntersect(LatLng a, LatLng b, LatLng c, LatLng d) {
  // Convert to simpler variable names for the algorithm
  double x1 = a.longitude, y1 = a.latitude;
  double x2 = b.longitude, y2 = b.latitude;
  double x3 = c.longitude, y3 = c.latitude;
  double x4 = d.longitude, y4 = d.latitude;

  // Calculate determinants
  double det = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
  if (det.abs() < 1e-10) return false; // Lines are parallel

  double t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / det;
  double u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / det;

  // Check if intersection is within both line segments
  return (t >= 0 && t <= 1 && u >= 0 && u <= 1);
}

// This class draws the track, current position, and start point
class ModernTrackPainter extends CustomPainter {
  final List<LatLng> trackPoints;
  final LatLng? currentPosition;
  final LatLng? startPoint;
  final Color trackColor;
  final Color positionColor;
  final Color gridColor;
  final bool trackCompleted;
  final LatLng? startLinePoint1;
  final LatLng? startLinePoint2;
  final bool isGpsAccurate;

  ModernTrackPainter({
    required this.trackPoints,
    this.currentPosition,
    this.startPoint,
    this.startLinePoint1,
    this.startLinePoint2,
    required this.trackColor,
    required this.positionColor,
    required this.gridColor,
    required this.trackCompleted,
    this.isGpsAccurate = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid
    _drawGrid(canvas, size);

    // If there aren't enough points, just draw the current position
    if (trackPoints.length < 2) {
      _drawCurrentPosition(canvas, size);
      return;
    }

    // Calculate bounds for all points
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    // Find min/max coordinates
    for (var point in trackPoints) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    // Add margins (10%)
    double latMargin = (maxLat - minLat) * 0.1;
    double lngMargin = (maxLng - minLng) * 0.1;

    minLat -= latMargin;
    maxLat += latMargin;
    minLng -= lngMargin;
    maxLng += lngMargin;

    // Transform track points to screen coordinates
    List<Offset> points = [];
    for (var point in trackPoints) {
      double x = (point.longitude - minLng) / (maxLng - minLng) * size.width;
      double y = (maxLat - point.latitude) / (maxLat - minLat) * size.height;
      points.add(Offset(x, y));
    }

    // Draw the track
    final trackPaint = Paint()
      ..color = trackCompleted ? const Color(0xFFFFD23F) : trackColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw fill if track is completed
    if (trackCompleted) {
      final fillPaint = Paint()
        ..color = trackColor.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      final path = Path();
      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        path.close();
        canvas.drawPath(path, fillPaint);
      }
    }

    // Draw track line
    if (points.length >= 2) {
      for (int i = 1; i < points.length; i++) {
        canvas.drawLine(points[i - 1], points[i], trackPaint);
      }

      // Close the loop if track is completed
      if (trackCompleted && points.length >= 2) {
        canvas.drawLine(points.last, points.first, trackPaint);
      }
    }

    // Draw start point
    if (startPoint != null) {
      double x =
          (startPoint!.longitude - minLng) / (maxLng - minLng) * size.width;
      double y =
          (maxLat - startPoint!.latitude) / (maxLat - minLat) * size.height;

      final startPaint = Paint()
        ..color = trackCompleted ? const Color(0xFFFFD23F) : trackColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 12, startPaint);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white);
    }

    // Draw start/finish line
    if (startLinePoint1 != null && startLinePoint2 != null) {
      double x1 = (startLinePoint1!.longitude - minLng) /
          (maxLng - minLng) *
          size.width;
      double y1 = (maxLat - startLinePoint1!.latitude) /
          (maxLat - minLat) *
          size.height;

      double x2 = (startLinePoint2!.longitude - minLng) /
          (maxLng - minLng) *
          size.width;
      double y2 = (maxLat - startLinePoint2!.latitude) /
          (maxLat - minLat) *
          size.height;

      final linePaint = Paint()
        ..color = trackCompleted ? const Color(0xFFFFD23F) : trackColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }

    // Draw current position
    if (currentPosition != null) {
      double x = (currentPosition!.longitude - minLng) /
          (maxLng - minLng) *
          size.width;
      double y = (maxLat - currentPosition!.latitude) /
          (maxLat - minLat) *
          size.height;

      // Position circle with pulse effect
      canvas.drawCircle(
          Offset(x, y), 20, Paint()..color = positionColor.withOpacity(0.3));

      // Inner circle
      canvas.drawCircle(Offset(x, y), 8, Paint()..color = positionColor);

      // White outline
      canvas.drawCircle(
          Offset(x, y),
          8,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      // Add accuracy indicator
      if (!isGpsAccurate) {
        canvas.drawCircle(
            Offset(x, y),
            25,
            Paint()
              ..color = Colors.red.withOpacity(0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Horizontal lines
    double spacing = size.height / 10;
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(
          Offset(0, i * spacing), Offset(size.width, i * spacing), gridPaint);
    }

    // Vertical lines
    spacing = size.width / 10;
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(
          Offset(i * spacing, 0), Offset(i * spacing, size.height), gridPaint);
    }
  }

  void _drawCurrentPosition(Canvas canvas, Size size) {
    if (currentPosition == null) return;

    // If no track points, draw in the center
    final point = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
        point, 20, Paint()..color = positionColor.withOpacity(0.3));
    canvas.drawCircle(point, 8, Paint()..color = positionColor);
    canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(ModernTrackPainter oldDelegate) {
    return oldDelegate.trackPoints != trackPoints ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.trackCompleted != trackCompleted;
  }
}

// Store previous position for line crossing detection
