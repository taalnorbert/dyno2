// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/speed_provider.dart'; // SpeedProvider importálása

// Közlekedési módok enum
enum TransportMode {
  walking('Gyaloglás', Icons.directions_walk, 5.0, 1, 2.0, 15.0),
  cycling('Kerékpár', Icons.directions_bike, 25.0, 2, 3.0, 25.0),
  driving('Autó', Icons.directions_car, 80.0, 3, 5.0, 50.0);

  const TransportMode(this.displayName, this.icon, this.maxSpeed,
      this.distanceFilter, this.minMovement, this.maxJump);

  final String displayName;
  final IconData icon;
  final double maxSpeed; // km/h-ban várható max sebesség
  final int distanceFilter; // GPS distance filter méterbben
  final double minMovement; // minimális mozgás méterben
  final double maxJump; // maximális GPS ugrás méterben
}

// LatLng osztály megtartása
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
  // Alapvető helymeghatározási változók megtartása
  final List<LatLng> _trackPoints = [];
  LatLng? _startPoint;
  LatLng? _currentPosition;
  bool _isRecording = false;
  bool _canComplete = false;
  bool _trackCompleted = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  final int _minPointsForCompletion = 30;
  final Duration _minRecordingTime = Duration(seconds: 10);
  DateTime? _recordingStartTime;
  DateTime? _trackCompletionTime;

  // SpeedProvider hozzáadása, a kódod többi része használhatja ezt
  final SpeedProvider _speedProvider = SpeedProvider();

  // Lap időmérés változók
  int _lapCount = 0;
  final List<Duration> _lapTimes = [];
  DateTime? _currentLapStartTime;

  // Animáció vezérlő
  late AnimationController _pulseAnimationController;

  // Design színek
  final Color _primaryRed = Color(0xFFE71D36);
  final Color _backgroundBlack = Color(0xFF121212);
  final Color _cardBlack = Color(0xFF1E1E1E);
  final Color _accentGrey = Color(0xFF333333);
  final Color _textWhite = Color(0xFFF5F5F5);
  final Color _highlightYellow = Color(0xFFFFD23F);

  // Rajtvonal pontok
  LatLng? _startLinePoint1;
  LatLng? _startLinePoint2;

  // GPS pontosságához szükséges
  bool _isGpsAccurate = false;

  // Korábbi pozíciók a szűréshez (megtartjuk a szűrési logikát)
  final List<LatLng> _recentPositions = [];
  final int _maxRecentPositions = 10;

  // Közlekedési mód kiválasztása
  TransportMode _selectedTransportMode = TransportMode.driving;

  @override
  void initState() {
    super.initState();

    // Animáció inicializálása
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // UI stílus beállítása
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _backgroundBlack,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _backgroundBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // SpeedProvider figyelése
    _speedProvider.addListener(_onSpeedChanged);

    // Helymeghatározás jogosultságok kérése
    _requestLocationPermission();
  }

  // SpeedProvider változásainak figyelése
  void _onSpeedChanged() {
    // Ez akkor hívódik meg, amikor változik a sebesség a SpeedProviderben
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pulseAnimationController.dispose();
    _speedProvider.removeListener(_onSpeedChanged);
    super.dispose();
  }

  // Helymeghatározás jogosultság kérése (eredeti kód megtartása)
  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
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

    // Indítsuk el a SpeedProvider-t, és használjuk annak helyzetmeghatározó szolgáltatását
    _speedProvider.startSpeedTracking();
    _startPositionTracking();
  }

  // Pozíció követés indítása - módosítva a SpeedProvider használatára
  void _startPositionTracking() {
    // A Geolocator szolgáltatását használjuk, a közlekedési mód alapján beállítva
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter:
            _selectedTransportMode.distanceFilter, // Dinamikus szűrés
      ),
    ).listen((Position position) {
      if (!mounted) return;

      // GPS position received with accuracy info
      // GPS pontosság ellenőrzése
      bool isAccurate =
          position.accuracy < 10.0; // 10 méteres pontossági küszöb
      setState(() {
        _isGpsAccurate = isAccurate;
      });

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // Helyzetszűrés alkalmazása a pontosság alapján
      newPosition = _applyAdvancedFiltering(newPosition, isAccurate);

      // Előző pozíció tárolása a vonal kereszteződés felismeréshez
      LatLng? prevPosition = _currentPosition;

      setState(() {
        _currentPosition = newPosition;

        // Ha rögzítés van, adjuk hozzá a pontot a pályához
        if (_isRecording) {
          // Adding point to track
          _trackPoints.add(newPosition);

          // Ha ez az első néhány pont, adjunk visszajelzést
          if (_trackPoints.length == 5) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pálya rögzítése folyamatban...'),
                duration: Duration(seconds: 2),
                backgroundColor: _primaryRed,
              ),
            );
          }

          // Ellenőrzés, hogy a pálya befejezhető-e
          if (_canComplete &&
              _trackPoints.length > _minPointsForCompletion &&
              _startLinePoint1 != null &&
              _startLinePoint2 != null &&
              prevPosition != null) {
            // Ellenőrizzük a vonalak kereszteződését
            bool crossing = _hasLineCrossing(
                prevPosition, newPosition, _startLinePoint1, _startLinePoint2);

            if (crossing) {
              _completeTrackRecording();
            }
          }
        }
        // Köridő mérés, ha a pálya már rögzítve van
        else if (_trackCompleted &&
            _startLinePoint1 != null &&
            _startLinePoint2 != null &&
            prevPosition != null) {
          // Ellenőrizzük a vonalak kereszteződését
          bool crossing = _hasLineCrossing(
              prevPosition, newPosition, _startLinePoint1, _startLinePoint2);

          if (crossing) {
            _onLapCompleted();
          }
        }
      });
    });
  }

  // Szűrési logika - stabilabb pozíció számítás
  LatLng _applyAdvancedFiltering(LatLng newPosition, bool isAccurate) {
    // Pozíciótörténet kezelése
    _recentPositions.add(newPosition);
    if (_recentPositions.length > _maxRecentPositions) {
      _recentPositions.removeAt(0);
    } // Ha van előző pozíció, ellenőrizzük a távolságot
    if (_currentPosition != null) {
      double distance = _calculateDistance(_currentPosition!, newPosition);

      // Közlekedési mód alapján állítjuk a szűrési paramétereket
      if (distance < _selectedTransportMode.minMovement) {
        return _currentPosition!;
      }

      // Ha túl nagy a mozgás, valószínűleg GPS hiba
      if (distance > _selectedTransportMode.maxJump && !isAccurate) {
        return _currentPosition!;
      }
    }

    // Ha nincs elég pozíció a szűréshez, használjuk az újat
    if (_recentPositions.length < 3) {
      return newPosition;
    }

    // Exponenciális súlyozott átlag a stabilabb megjelenítésért
    if (_recentPositions.length >= 3) {
      double totalWeight = 0.0;
      double weightedLat = 0.0;
      double weightedLng = 0.0;

      for (int i = 0; i < _recentPositions.length; i++) {
        // Újabb pozíciók nagyobb súlyt kapnak
        double weight = (i + 1) * (i + 1).toDouble(); // Kvadratikus súlyozás
        totalWeight += weight;
        weightedLat += _recentPositions[i].latitude * weight;
        weightedLng += _recentPositions[i].longitude * weight;
      }

      LatLng filteredPosition = LatLng(
        weightedLat / totalWeight,
        weightedLng / totalWeight,
      );

      return filteredPosition;
    }

    return newPosition;
  }
  // Transport mode implementation moved to _startTrackRecording method

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

  // Építi fel a közlekedési mód kiválasztó UI-t
  Widget _buildTransportModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentGrey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cím
          Row(
            children: [
              Icon(
                Icons.directions,
                color: _primaryRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Közlekedési mód',
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Közlekedési módok választó
          Row(
            children: TransportMode.values.map((mode) {
              final isSelected = _selectedTransportMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: _isRecording
                      ? null
                      : () {
                          setState(() {
                            _selectedTransportMode = mode;
                          });
                          // Feedback a felhasználónak
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${mode.displayName} mód kiválasztva'),
                              backgroundColor: _primaryRed,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: mode != TransportMode.values.last ? 8 : 0,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryRed.withOpacity(0.2)
                          : _accentGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _primaryRed
                            : _accentGrey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          mode.icon,
                          color: isSelected
                              ? _primaryRed
                              : _textWhite.withOpacity(0.7),
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          mode.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? _primaryRed
                                : _textWhite.withOpacity(0.7),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Információs szöveg a kiválasztott módról
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getTransportModeInfo(_selectedTransportMode),
              style: TextStyle(
                color: _textWhite.withOpacity(0.6),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Információs szöveg a kiválasztott közlekedési módhoz
  String _getTransportModeInfo(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
        return 'Pontosság: ${mode.distanceFilter}m szűrő • Min. mozgás: ${mode.minMovement}m • Max. ugrás: ${mode.maxJump}m';
      case TransportMode.cycling:
        return 'Pontosság: ${mode.distanceFilter}m szűrő • Min. mozgás: ${mode.minMovement}m • Max. ugrás: ${mode.maxJump}m';
      case TransportMode.driving:
        return 'Pontosság: ${mode.distanceFilter}m szűrő • Min. mozgás: ${mode.minMovement}m • Max. ugrás: ${mode.maxJump}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundBlack,
      appBar: AppBar(
        backgroundColor: _cardBlack,
        title: Text(
          'Köridő mérés',
          style: TextStyle(
            color: _textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textWhite),
          onPressed: () {
            // Használd a context.pop() helyett a következőt:
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              // Navigálj a megfelelő kezdőképernyőre
              context.go('/home'); // vagy más alapértelmezett útvonal
            }
          },
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Transport mode selector
          _buildTransportModeSelector(),

          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusBarColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getTrackBorderColor(),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimationController,
                      builder: (context, child) {
                        return Icon(
                          _trackCompleted
                              ? Icons.flag
                              : _isRecording
                                  ? Icons.fiber_manual_record
                                  : Icons.location_off,
                          color: _getStatusTextColor().withOpacity(_isRecording
                              ? 0.5 + 0.5 * _pulseAnimationController.value
                              : 1.0),
                          size: 24,
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusTextColor(),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_trackCompleted && _lapTimes.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Divider(color: _accentGrey),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoColumn('Körök', '$_lapCount'),
                      _infoColumn(
                          'Utolsó kör',
                          _lapTimes.isNotEmpty
                              ? _formatDuration(_lapTimes.last)
                              : '--'),
                      _infoColumn(
                          'Legjobb kör',
                          _lapTimes.isNotEmpty
                              ? _formatDuration(
                                  _lapTimes.reduce((a, b) => a < b ? a : b))
                              : '--'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Track display area
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getTrackBorderColor(),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _trackPoints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 64,
                              color: _accentGrey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nincs rögzített pálya',
                              style: TextStyle(
                                color: _textWhite,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Válasszon közlekedési módot és kezdje el a rögzítést',
                              style: TextStyle(
                                color: _textWhite.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : CustomPaint(
                        painter: ModernTrackPainter(
                          trackPoints: _trackPoints,
                          currentPosition: _currentPosition,
                          startPoint: _startPoint,
                          trackColor: _getTrackBorderColor(),
                          positionColor: _primaryRed,
                          gridColor: _accentGrey,
                          trackCompleted: _trackCompleted,
                          startLinePoint1: _startLinePoint1,
                          startLinePoint2: _startLinePoint2,
                          isGpsAccurate: _isGpsAccurate,
                        ),
                        child: Container(),
                      ),
              ),
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!_trackCompleted) ...[
                  Expanded(
                    child: _buildControlButton(
                      icon: _isRecording ? Icons.stop : Icons.play_arrow,
                      label: _isRecording ? 'Állj' : 'Rögzítés',
                      onPressed: _isRecording
                          ? _completeTrackRecording
                          : _startTrackRecording,
                      backgroundColor:
                          _isRecording ? _primaryRed : Colors.green,
                      foregroundColor: _textWhite,
                      isActive: _isRecording,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.refresh,
                      label: 'Törlés',
                      onPressed:
                          _trackPoints.isNotEmpty ? _resetTracking : null,
                      backgroundColor: _accentGrey,
                      foregroundColor: _textWhite,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _buildControlButton(
                      icon: Icons.refresh,
                      label: 'Új pálya',
                      onPressed: _resetTracking,
                      backgroundColor: _highlightYellow,
                      foregroundColor: _backgroundBlack,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _textWhite.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // A többi metódus megtartása
  void _startTrackRecording() async {
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

    // Wait for enough points to determine initial direction
    Future.delayed(Duration(seconds: 3), () {
      if (_trackPoints.length > 10) {
        // Calculate initial direction from first points
        LatLng initialDirection =
            _calculateDirection(_trackPoints.sublist(0, 10));

        // Create perpendicular start/finish line
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

    // Wait for MORE points for better direction calculation
    Future.delayed(Duration(seconds: 5), () {
      if (_trackPoints.length > 20) {
        // More points for accurate direction
        // Use last 10 points to determine direction
        List<LatLng> recentPoints = _trackPoints.length > 10
            ? _trackPoints.sublist(_trackPoints.length - 10)
            : _trackPoints;

        LatLng direction = _calculateDirection(recentPoints);

        // 15 meter start line in both directions
        _startLinePoint1 =
            _createOffsetPoint(_startPoint!, direction, 15, true);
        _startLinePoint2 =
            _createOffsetPoint(_startPoint!, direction, 15, false);

        setState(() {}); // UI refresh
      }
    });

    // Enable completion after minimum time
    Future.delayed(_minRecordingTime, () {
      if (_isRecording && mounted) {
        setState(() {
          _canComplete = true;
        });
      }
    });
  }

  // Calculate distance between two LatLng points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Check if two lines cross each other
  bool _hasLineCrossing(
      LatLng start1, LatLng end1, LatLng? start2, LatLng? end2) {
    if (start2 == null || end2 == null) return false;

    // Convert to normalized coordinates for calculation
    double x1 = start1.latitude;
    double y1 = start1.longitude;
    double x2 = end1.latitude;
    double y2 = end1.longitude;
    double x3 = start2.latitude;
    double y3 = start2.longitude;
    double x4 = end2.latitude;
    double y4 = end2.longitude;

    // Calculate line crossing using standard mathematical formula
    double denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denom.abs() < 1e-10) return false; // Lines are parallel

    double t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    double u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  // Calculate movement direction from a list of points
  LatLng _calculateDirection(List<LatLng> points) {
    if (points.length < 2) return LatLng(0, 0);

    double totalLatDiff = 0;
    double totalLngDiff = 0;

    for (int i = 1; i < points.length; i++) {
      totalLatDiff += points[i].latitude - points[i - 1].latitude;
      totalLngDiff += points[i].longitude - points[i - 1].longitude;
    }

    // Normalize the direction vector
    double magnitude =
        math.sqrt(totalLatDiff * totalLatDiff + totalLngDiff * totalLngDiff);
    if (magnitude == 0) return LatLng(0, 0);

    return LatLng(totalLatDiff / magnitude, totalLngDiff / magnitude);
  }

  // Create an offset point perpendicular to the movement direction
  LatLng _createOffsetPoint(
      LatLng center, LatLng direction, double distance, bool leftSide) {
    // Create perpendicular vector
    double perpLat = leftSide ? -direction.longitude : direction.longitude;
    double perpLng = leftSide ? direction.latitude : -direction.latitude;

    // Convert distance from meters to degrees (approximate)
    double distanceInDegrees =
        distance / 111000.0; // Rough conversion: 1 degree ≈ 111km

    return LatLng(
      center.latitude + perpLat * distanceInDegrees,
      center.longitude + perpLng * distanceInDegrees,
    );
  }
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

  // Add the missing _drawGrid method
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const double spacing = 20.0;

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Háttérrács rajzolása
    _drawGrid(canvas, size);

    // Ha nincs pont, de van aktuális pozíció, azt rajzoljuk
    if ((trackPoints.isEmpty || trackPoints.length < 2) &&
        currentPosition != null) {
      final Paint posPaint = Paint()
        ..color = positionColor
        ..style = PaintingStyle.fill;
      final Offset pos = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(pos, 10, posPaint);
      return;
    }

    // Koordináta határok számítása
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    // Minimum és maximum koordináták keresése
    for (var point in trackPoints) {
      if (point.latitude.isFinite && point.longitude.isFinite) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
    }
    // Ha van aktuális pozíció, vegyük figyelembe a határoknál
    if (currentPosition != null &&
        currentPosition!.latitude.isFinite &&
        currentPosition!.longitude.isFinite) {
      minLat = math.min(minLat, currentPosition!.latitude);
      maxLat = math.max(maxLat, currentPosition!.latitude);
      minLng = math.min(minLng, currentPosition!.longitude);
      maxLng = math.max(maxLng, currentPosition!.longitude);
    }

    // Biztonsági ellenőrzés: ha nincs valós tartomány vagy túl kicsi a tartomány
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    if (latDiff.abs() < 1e-8) latDiff = 1e-8;
    if (lngDiff.abs() < 1e-8) lngDiff = 1e-8;

    // Padding a szélekhez
    const double padding = 24.0;
    final double w = size.width - 2 * padding;
    final double h = size.height - 2 * padding;

    // Koordináta transzformáció: geo -> képernyő
    Offset geoToScreen(LatLng p) {
      double x = ((p.longitude - minLng) / lngDiff) * w + padding;
      double y = h - ((p.latitude - minLat) / latDiff) * h + padding;
      if (!x.isFinite || !y.isFinite) {
        return Offset(size.width / 2, size.height / 2);
      }
      return Offset(x, y);
    }

    // Track kirajzolása
    if (trackPoints.length >= 2) {
      final Paint trackPaint = Paint()
        ..color = trackColor
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      final Path path = Path();
      for (int i = 0; i < trackPoints.length; i++) {
        final Offset pt = geoToScreen(trackPoints[i]);
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, trackPaint);
    }

    // Start/cél vonal kirajzolása
    if (startLinePoint1 != null && startLinePoint2 != null) {
      final Paint startLinePaint = Paint()
        ..color = trackCompleted ? positionColor : trackColor
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      final Offset p1 = geoToScreen(startLinePoint1!);
      final Offset p2 = geoToScreen(startLinePoint2!);
      canvas.drawLine(p1, p2, startLinePaint);
    }

    // Start pont kirajzolása
    if (startPoint != null) {
      final Paint startPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final Offset start = geoToScreen(startPoint!);
      canvas.drawCircle(start, 8, startPaint);
      final Paint borderPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(start, 10, borderPaint);
    }

    // Aktuális pozíció kirajzolása
    if (currentPosition != null) {
      final Paint posPaint = Paint()
        ..color = isGpsAccurate ? positionColor : Colors.grey
        ..style = PaintingStyle.fill;
      final Offset pos = geoToScreen(currentPosition!);
      canvas.drawCircle(pos, 10, posPaint);
      final Paint borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, 12, borderPaint);
    }
  }

  // Add the missing shouldRepaint method
  @override
  bool shouldRepaint(ModernTrackPainter oldDelegate) {
    return oldDelegate.trackPoints != trackPoints ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.trackCompleted != trackCompleted ||
        oldDelegate.isGpsAccurate != isGpsAccurate;
  }
}
