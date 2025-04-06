import 'package:flutter/material.dart';
import 'package:dyno2/speed_meter/Navbar/Button_navbar.dart';
import '../../speedmeter.dart';
import 'package:dyno2/login/login.dart';
import '../../../services/auth_service.dart';
import 'laptime.dart';
import 'performance.dart';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  int _selectedIndex = 1; // A CompetitionsPage indexe 1
  int _selectedLeaderboardType = 0; // 0: 0-100, 1: 100-200, 2: 1/4 mérföld

  // Példa adatok a leaderboardhoz
  final List<List<Map<String, dynamic>>> _leaderboardData = [
    // 0-100 adatok
    [
      {'username': 'SpeedDemon', 'car': 'BMW M4', 'time': 3.9},
      {'username': 'RacerX', 'car': 'Audi RS7', 'time': 4.1},
      {'username': 'NitroBoost', 'car': 'Mercedes AMG GT', 'time': 4.2},
      {'username': 'DriftKing', 'car': 'Toyota Supra', 'time': 4.3},
      {'username': 'ThunderBolt', 'car': 'Tesla Model S', 'time': 4.5},
      {'username': 'FastLane', 'car': 'Porsche 911', 'time': 4.6},
      {'username': 'RoadRunner', 'car': 'Lamborghini Huracan', 'time': 4.7},
      {'username': 'TurboCharge', 'car': 'Ferrari 488', 'time': 4.8},
      {'username': 'NightRider', 'car': 'Nissan GTR', 'time': 4.9},
      {'username': 'BurnoutKing', 'car': 'Chevrolet Corvette', 'time': 5.0},
      {'username': 'AsphaltLegend', 'car': 'Dodge Challenger', 'time': 5.1},
      {'username': 'QuarterMile', 'car': 'Ford Mustang', 'time': 5.2},
      {'username': 'TurboTom', 'car': 'Hyundai i30N', 'time': 5.3},
      {'username': 'SpeedStar', 'car': 'Subaru WRX', 'time': 5.4},
      {'username': 'DragRacer', 'car': 'Honda Civic Type R', 'time': 5.5},
      {'username': 'LightSpeed', 'car': 'VW Golf R', 'time': 5.6},
      {'username': 'PowerShift', 'car': 'Mazda MX-5', 'time': 5.7},
      {'username': 'RacingBeast', 'car': 'Jaguar F-Type', 'time': 5.8},
      {'username': 'MidnightRacer', 'car': 'Kia Stinger', 'time': 5.9},
      {'username': 'SpeedHunter', 'car': 'Lexus RC F', 'time': 6.0},
    ],
    // 100-200 adatok
    [
      {'username': 'AeroDynamic', 'car': 'McLaren 720S', 'time': 6.1},
      {'username': 'SpeedForce', 'car': 'Ferrari SF90', 'time': 6.3},
      {'username': 'PistonHead', 'car': 'Lamborghini Aventador', 'time': 6.4},
      {'username': 'SuperCharger', 'car': 'Bugatti Chiron', 'time': 6.5},
      {'username': 'HighwayHero', 'car': 'Porsche Taycan', 'time': 6.7},
      {'username': 'TopGear', 'car': 'Aston Martin DBS', 'time': 6.8},
      {'username': 'TurboJet', 'car': 'Koenigsegg Jesko', 'time': 6.9},
      {'username': 'FastLane', 'car': 'BMW M8', 'time': 7.1},
      {'username': 'BoostMode', 'car': 'Mercedes AMG E63S', 'time': 7.2},
      {'username': 'RevLimiter', 'car': 'Audi RS6', 'time': 7.3},
      {'username': 'SpeedMachine', 'car': 'Tesla Model 3 Performance', 'time': 7.4},
      {'username': 'QuarterMaster', 'car': 'Dodge Charger Hellcat', 'time': 7.5},
      {'username': 'RaceReady', 'car': 'Lexus LFA', 'time': 7.6},
      {'username': 'RoadWarrior', 'car': 'Maserati MC20', 'time': 7.7},
      {'username': 'DriftLord', 'car': 'Nissan 400Z', 'time': 7.8},
      {'username': 'SpeedDaemon', 'car': 'Chevrolet Camaro ZL1', 'time': 7.9},
      {'username': 'BurnRubber', 'car': 'Ford Shelby GT500', 'time': 8.0},
      {'username': 'DreamRide', 'car': 'Lotus Emira', 'time': 8.1},
      {'username': 'PerformancePro', 'car': 'Alfa Romeo Giulia', 'time': 8.2},
      {'username': 'SprintMaster', 'car': 'BMW M5', 'time': 8.3},
    ],
    // 1/4 mérföld adatok
    [
      {'username': 'DragKing', 'car': 'Dodge Demon', 'time': 10.2},
      {'username': 'QuarterHero', 'car': 'Tesla Model S Plaid', 'time': 10.4},
      {'username': 'LineBreaker', 'car': 'McLaren 765LT', 'time': 10.5},
      {'username': 'SpeedVision', 'car': 'Ferrari F8', 'time': 10.6},
      {'username': 'QuarterLegend', 'car': 'Lamborghini Huracan STO', 'time': 10.7},
      {'username': 'TrackStar', 'car': 'Porsche 911 Turbo S', 'time': 10.8},
      {'username': 'SpeedRacer', 'car': 'Chevrolet Corvette C8', 'time': 10.9},
      {'username': 'PowerRush', 'car': 'Nissan GTR Nismo', 'time': 11.0},
      {'username': 'DragsterPro', 'car': 'BMW M4 Competition', 'time': 11.1},
      {'username': 'StripMaster', 'car': 'Audi RS7', 'time': 11.2},
      {'username': 'NitroKing', 'car': 'Dodge Challenger Hellcat', 'time': 11.3},
      {'username': 'LaunchControl', 'car': 'Mercedes AMG GT Black Series', 'time': 11.4},
      {'username': 'LightSpeed', 'car': 'Ford Mustang Shelby GT500', 'time': 11.5},
      {'username': 'QuarterSpecialist', 'car': 'Lexus RC F Track Edition', 'time': 11.6},
      {'username': 'SpeedTrack', 'car': 'Jaguar F-Type R', 'time': 11.7},
      {'username': 'DragProdigy', 'car': 'Chevrolet Camaro ZL1 1LE', 'time': 11.8},
      {'username': 'SprintStar', 'car': 'Subaru WRX STI', 'time': 11.9},
      {'username': 'MileStone', 'car': 'Porsche Cayman GT4', 'time': 12.0},
      {'username': 'RacerEdge', 'car': 'Toyota Supra', 'time': 12.1},
      {'username': 'SpeedMarker', 'car': 'Honda Civic Type R', 'time': 12.2},
    ],
  ];


  String _getLeaderboardTitle() {
    switch (_selectedLeaderboardType) {
      case 0:
        return "0-100 km/h";
      case 1:
        return "100-200 km/h";
      case 2:
        return "1/4 Mile";
      default:
        return "Versenyek";
    }
  }

  String _getTimeUnit() {
    return _selectedLeaderboardType == 2 ? "sec" : "mp";
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLeaderboardTitle(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {
              // Itt lehetne implementálni a dátumválasztást
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mai nap adatait látod'))
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Kategória választó
          Container(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryButton(0, "0-100"),
                _buildCategoryButton(1, "100-200"),
                _buildCategoryButton(2, "1/4 Mile"),
              ],
            ),
          ),

          // Leaderboard lista
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Lista fejléc
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 30),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Felhasználó",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Autó",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            "Idő",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista elemek
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: _leaderboardData[_selectedLeaderboardType].length,
                      itemBuilder: (context, index) {
                        final item = _leaderboardData[_selectedLeaderboardType][index];
                        return _buildLeaderboardItem(index, item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Frissítés gomb
          Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Frissítve!'))
                );
              },
              icon: Icon(Icons.refresh, color: Colors.black),
              label: Text(
                "Frissítés",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
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

  Widget _buildCategoryButton(int index, String title) {
    final isSelected = _selectedLeaderboardType == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLeaderboardType = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(int index, Map<String, dynamic> item) {
    // Első három helyezett színei
    Color? rankColor;
    if (index == 0) {
      rankColor = Colors.amber;  // Arany
    } else if (index == 1) {
      rankColor = Colors.grey[400];  // Ezüst
    } else if (index == 2) {
      rankColor = Colors.brown[300];  // Bronz
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.black.withOpacity(0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Helyezés
          Container(
            width: 30,
            child: Text(
              "${index + 1}.",
              style: TextStyle(
                color: rankColor ?? Colors.white,
                fontWeight: rankColor != null ? FontWeight.bold : FontWeight.normal,
                fontSize: rankColor != null ? 16 : 14,
              ),
            ),
          ),

          // Felhasználói név
          Expanded(
            flex: 2,
            child: Text(
              item['username'],
              style: TextStyle(
                color: Colors.white,
                fontWeight: rankColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Autó típus
          Expanded(
            flex: 3,
            child: Text(
              item['car'],
              style: TextStyle(
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Idő
          Container(
            width: 70,
            child: Text(
              "${item['time']} ${_getTimeUnit()}",
              textAlign: TextAlign.end,
              style: TextStyle(
                color: rankColor ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}