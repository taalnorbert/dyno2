import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:dyno2/login/login.dart';
import 'package:dyno2/speed_meter/Navbar/button_navbar.dart';
import '../../../services/auth_service.dart';
import '../../speedmeter.dart';
import 'competitions.dart';
import 'laptime.dart';

// ignore: camel_case_types
class dynoscreen extends StatefulWidget {
  const dynoscreen({super.key});

  @override
  State<dynoscreen> createState() => _dynoscreenState();
}

// ignore: camel_case_types
class _dynoscreenState extends State<dynoscreen> {
  int _selectedIndex = 3;
  final TextEditingController weightController = TextEditingController();
  final TextEditingController rimSizeController = TextEditingController();
  final TextEditingController tireSizeController = TextEditingController();
  final TextEditingController accelerationTimeController =
      TextEditingController();
  final TextEditingController rpmAt100Controller = TextEditingController();

  // Új controller a fordulatszámhoz
  int gearAt100 = 3; // Alapértelmezett: 3. fokozat
  int vehicleType = 1; // Alapértelmezett: személyautó

  double speed = 0.0;
  double previousSpeed = 0.0;
  double acceleration = 0.0;
  double horsepower = 0.0;
  double torque = 0.0;
  DateTime? lastSpeedUpdate;

  // Járműtípusok áttételi arányai (egyszerűsített)
  final Map<int, List<double>> _gearRatios = {
    1: [3.91, 2.39, 1.55, 1.16, 0.85], // Személyautó
    2: [4.17, 2.64, 1.77, 1.27, 1.00], // SUV/terepjáró
    3: [5.05, 2.97, 1.94, 1.34, 1.00], // Kisteherautó
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (index == 0) {
      navigator
          .push(MaterialPageRoute(builder: (context) => const SpeedMeter()));
    } else if (index == 1) {
      navigator.push(
          MaterialPageRoute(builder: (context) => const CompetitionsPage()));
    } else if (index == 2) {
      navigator
          .push(MaterialPageRoute(builder: (context) => const SpeedMeter()));
    } else if (index == 3 || index == 4) {
      final user = AuthService().currentUser;
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (user == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 10),
                Text("Must be logged in!",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
        navigator.push(MaterialPageRoute(builder: (context) => Login()));
      } else {
        if (index == 3) {
          navigator.push(
              MaterialPageRoute(builder: (context) => const dynoscreen()));
        } else if (index == 4) {
          navigator.pushReplacement(
              MaterialPageRoute(builder: (context) => const LapTimeScreen()));
        }
      }
    }
  }

  void _getSpeed() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      DateTime now = DateTime.now();

      if (!mounted) return;

      if (lastSpeedUpdate != null) {
        double timeDiff =
            now.difference(lastSpeedUpdate!).inMilliseconds / 1000.0;
        if (timeDiff > 0) {
          acceleration = (position.speed - previousSpeed) / timeDiff;
        }
      }

      setState(() {
        previousSpeed = speed;
        speed = position.speed;
        lastSpeedUpdate = now;
      });
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Hiba a sebesség lekérése során: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculatePerformance() {
    // Klasszikus számítás a régi kód alapján
    if (weightController.text.isNotEmpty) {
      double weight = double.tryParse(weightController.text) ?? 0.0;
      if (weight > 0 && acceleration > 0) {
        setState(() {
          horsepower = (weight * acceleration * speed) / 745.7;
          torque = horsepower * 5252 / max(speed, 1.0);
        });
        return;
      }
    }

    // Újfajta számítás, 0-100-as gyorsulás alapján
    if (weightController.text.isNotEmpty &&
        accelerationTimeController.text.isNotEmpty &&
        rpmAt100Controller.text.isNotEmpty) {
      double weight = double.tryParse(weightController.text) ?? 0.0;
      double accelerationTime =
          double.tryParse(accelerationTimeController.text) ?? 0.0;
      double rpmAt100 = double.tryParse(rpmAt100Controller.text) ?? 0.0;

      if (weight > 0 && accelerationTime > 0 && rpmAt100 > 0) {
        // 1. Nyomaték számítása a gyorsulási adatokból
        // v = 100 km/h = 27.78 m/s
        const velocity = 27.78; // m/s
        final accelerationCalc = velocity / accelerationTime;
        final force = weight * accelerationCalc;

        // Becslés a kerék rádiuszára (átlagos személyautó)
        double wheelRadius = 0.33; // méter (kb. egy 16" kerék sugara)

        // Ha megadták a felni és kerék méretet, akkor használjuk azt
        if (rimSizeController.text.isNotEmpty &&
            tireSizeController.text.isNotEmpty) {
          double rimSize = double.tryParse(rimSizeController.text) ?? 0.0;
          double tireSize = double.tryParse(tireSizeController.text) ?? 0.0;

          if (rimSize > 0 && tireSize > 0) {
            // Átváltás colból méterbe (1 col = 0.0254 méter)
            double rimSizeMeters = rimSize * 0.0254;

            // Átváltás mm-ből méterbe és hozzáadás a felni méretéhez
            double tireSizeMeters = tireSize / 1000;

            // Teljes kerék sugara
            wheelRadius = (rimSizeMeters + tireSizeMeters) / 2;
          }
        }

        // Alap nyomaték a keréknél
        final wheelTorque = force * wheelRadius;

        // Az áttételi arány figyelembevétele
        final gearRatio = _gearRatios[vehicleType]![gearAt100 - 1];
        final differentialRatio =
            vehicleType == 1 ? 3.45 : (vehicleType == 2 ? 3.73 : 4.10);

        // Becsült motor nyomaték
        double calculatedTorque = wheelTorque / (gearRatio * differentialRatio);

        // Hatásfok figyelembevétele (kb. 85%)
        calculatedTorque = calculatedTorque / 0.85;

        // 2. Lóerő számítása a nyomatékból és fordulatszámból
        // P(W) = T(Nm) * ω(rad/s)
        // ω(rad/s) = RPM * 2π / 60
        final angularVelocity = (rpmAt100 * 2 * pi) / 60;
        final powerWatts = calculatedTorque * angularVelocity;

        // Átváltás lóerőre (1 LE ≈ 735.5 W)
        double calculatedHorsepower = powerWatts / 735.5;

        // Korrekciós tényező a jármű típusa alapján
        final correctionFactor =
            vehicleType == 1 ? 1.05 : (vehicleType == 2 ? 1.15 : 1.2);
        calculatedHorsepower = calculatedHorsepower * correctionFactor;

        setState(() {
          torque = calculatedTorque;
          horsepower = calculatedHorsepower;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Teljesítménymérés", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Járműadatok",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            SizedBox(height: 10),

            // Jármű típus választás
            Text("Jármű típusa:", style: TextStyle(color: Colors.white)),
            Row(
              children: [
                Radio(
                  value: 1,
                  groupValue: vehicleType,
                  onChanged: (value) {
                    setState(() {
                      vehicleType = value as int;
                    });
                  },
                  fillColor: WidgetStateProperty.all(Colors.white),
                ),
                Text('Személyautó', style: TextStyle(color: Colors.white)),
                Radio(
                  value: 2,
                  groupValue: vehicleType,
                  onChanged: (value) {
                    setState(() {
                      vehicleType = value as int;
                    });
                  },
                  fillColor: WidgetStateProperty.all(Colors.white),
                ),
                Text('SUV/Terepjáró', style: TextStyle(color: Colors.white)),
              ],
            ),
            Row(
              children: [
                Radio(
                  value: 3,
                  groupValue: vehicleType,
                  onChanged: (value) {
                    setState(() {
                      vehicleType = value as int;
                    });
                  },
                  fillColor: WidgetStateProperty.all(Colors.white),
                ),
                Text('Kisteher', style: TextStyle(color: Colors.white)),
              ],
            ),
            SizedBox(height: 10),

            TextField(
              controller: weightController,
              decoration: InputDecoration(
                  labelText: "Autó súlya (kg)",
                  filled: true,
                  fillColor: Colors.white),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            TextField(
              controller: rimSizeController,
              decoration: InputDecoration(
                  labelText: "Felni mérete (col)",
                  filled: true,
                  fillColor: Colors.white),
              keyboardType: TextInputType.number,
            ),

            TextField(
              controller: tireSizeController,
              decoration: InputDecoration(
                  labelText: "Kerék mérete (mm)",
                  filled: true,
                  fillColor: Colors.white),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20),
            Text("2. Mérési adatok",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getSpeed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Élő sebesség mérése"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
            Text("VAGY",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            TextField(
              controller: accelerationTimeController,
              decoration: InputDecoration(
                  labelText: "Gyorsulási idő 0-100 km/h (mp)",
                  filled: true,
                  fillColor: Colors.white),
              keyboardType: TextInputType.number,
            ),

            TextField(
              controller: rpmAt100Controller,
              decoration: InputDecoration(
                  labelText: "Fordulatszám 100 km/h-nál (RPM)",
                  filled: true,
                  fillColor: Colors.white),
              keyboardType: TextInputType.number,
            ),

            // Fokozat 100 km/h-nál
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                  labelText: 'Fokozat 100 km/h-nál',
                  filled: true,
                  fillColor: Colors.white),
              value: gearAt100,
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(value: 1, child: Text('1. fokozat')),
                DropdownMenuItem(value: 2, child: Text('2. fokozat')),
                DropdownMenuItem(value: 3, child: Text('3. fokozat')),
                DropdownMenuItem(value: 4, child: Text('4. fokozat')),
                DropdownMenuItem(value: 5, child: Text('5. fokozat')),
              ],
              onChanged: (value) {
                setState(() {
                  gearAt100 = value!;
                });
              },
            ),

            SizedBox(height: 20),

            Text("Aktuális sebesség: ${speed.toStringAsFixed(2)} m/s",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _calculatePerformance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text("TELJESÍTMÉNY KISZÁMÍTÁSA",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                children: [
                  Text("MÉRÉSI EREDMÉNYEK",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("LÓERŐ:",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text("${horsepower.toStringAsFixed(1)} HP",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("NYOMATÉK:",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text("${torque.toStringAsFixed(1)} Nm",
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        currentSpeed: speed,
        isLocationServiceEnabled: true,
        showMovementWarning: () {},
        showMovementTooHigh: () {},
        onItemTappedInternal: _onItemTapped,
      ),
    );
  }
}
