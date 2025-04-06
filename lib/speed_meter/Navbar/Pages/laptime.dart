import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/auth_service.dart'; // Importáld az AuthService-t
import 'package:dyno2/speed_meter/Navbar/Pages/performance.dart';
import '../../speedmeter.dart'; // Importáld a SpeedMeter oldalt
import 'package:dyno2/login/login.dart'; // Importáld a Login oldalt
import 'competitions.dart';
import 'package:dyno2/speed_meter/Navbar/Button_navbar.dart'; // Importáld a BottomNavBar widgetet


class LapTimeScreen extends StatefulWidget {
  const LapTimeScreen({super.key});

  @override
  State<LapTimeScreen> createState() =>_LapTimeScreenState();
}

class _LapTimeScreenState extends State<LapTimeScreen> {
  int _selectedIndex = 4;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigáció az egyes oldalak között
    if (index == 0) {
      // Mérés oldalra navigálás
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SpeedMeter()),
      );
    } else if (index == 1) {
      // Competitions oldalra navigálás (maradunk ugyanitt)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CompetitionsPage()),
      );
    } else if (index == 2) {
      // Kezdőlapra navigálás
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SpeedMeter()),
      );
    } else if (index == 3 || index == 4) {
      // Teljesítmény vagy köridő oldalra navigálás (csak bejelentkezett felhasználóknak)
      final user = AuthService().currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Must be logged in!",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      } else {
        // Ha be van jelentkezve, navigálj a megfelelő oldalra
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const dynoscreen()),
          );
        } else if (index == 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LapTimeScreen()),
          );
        }
      }
    }
  }

  final List<LatLng> _trackPoints = [];
  bool _isRecording = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  final int _minPointsForCompletion = 20; // Minimális pontszám a pálya befejezéséhez
  bool _isStartPointChecked = false; // Ellenőrizve lett-e már a kezdőpont

  void _startRecording() {
    setState(() {
      _trackPoints.clear();
      _isRecording = true;
      _isStartPointChecked = false; // Új rögzítéskor alaphelyzetbe állítjuk
    });
    _trackLocation();
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _positionStreamSubscription?.cancel();
  }

  void _trackLocation() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: Duration(seconds: 1),
      ),
    ).listen((Position position) {
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        _trackPoints.add(newPoint);
      });

      // Csak akkor ellenőrizzük a kezdőpontot, ha elértük a minimális pontszámot
      if (_trackPoints.length > _minPointsForCompletion && !_isStartPointChecked) {
        if (_isCloseToStart(newPoint)) {
          _isStartPointChecked = true; // Megjelöljük, hogy ellenőrizve lett
          _stopRecording();
        }
      }
    });
  }

  bool _isCloseToStart(LatLng point) {
    if (_trackPoints.isEmpty) return false;
    double distance = Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      _trackPoints.first.latitude,
      _trackPoints.first.longitude,
    );
    return distance < 10; // 10 méteren belül visszaértünk a kiindulási ponthoz
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Pályarögzítés", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(20),
            height: 400, // Magas téglalap a pálya számára
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: TrackPainter(_trackPoints),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? null : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    "Pályafelvétele",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(
                    "Vissza",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        currentSpeed: 0.0, // Nem használjuk a CompetitionsPage-en
        isLocationServiceEnabled: true, // Nem használjuk a CompetitionsPage-en
        showMovementWarning: () {}, // Nem használjuk a CompetitionsPage-en
        showMovementTooHigh: () {}, // Nem használjuk a CompetitionsPage-en
        onItemTappedInternal: _onItemTapped,
      ),

    );
  }
}

class TrackPainter extends CustomPainter {
  final List<LatLng> points;

  TrackPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final path = Path();

    double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    double scaleX = size.width / (maxLng - minLng + 0.0001);
    double scaleY = size.height / (maxLat - minLat + 0.0001);

    double startX = (points[0].longitude - minLng) * scaleX;
    double startY = size.height - (points[0].latitude - minLat) * scaleY;
    path.moveTo(startX, startY);

    for (var point in points) {
      double x = (point.longitude - minLng) * scaleX;
      double y = size.height - (point.latitude - minLat) * scaleY;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}