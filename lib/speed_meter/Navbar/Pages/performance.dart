import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';

class DynoScreen extends StatefulWidget {
  const DynoScreen({super.key});

  @override
  State<DynoScreen> createState() => _DynoScreenState();
}

class _DynoScreenState extends State<DynoScreen> {
  final TextEditingController _weightController =
      TextEditingController(text: '1500');
  final TextEditingController _wheelRadiusController =
      TextEditingController(text: '0.3');

  // Mérési értékek
  double _speed = 0.0;
  double _previousSpeed = 0.0;
  double _acceleration = 0.0;
  double _maxHorsepower = 0.0;
  double _maxTorque = 0.0;
  DateTime? _lastSpeedUpdate;

  // Konfiguráció
  static const Duration _measurementInterval = Duration(milliseconds: 200);

  // Grafikon adatok
  final List<FlSpot> _horsepowerData = [];
  final List<FlSpot> _torqueData = [];
  int _measurementIndex = 0;

  // Állapotkezelés
  Timer? _measurementTimer;
  bool _isMeasuring = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Ellenőrizzük, hogy a helymeghatározás szolgáltatás engedélyezve van-e
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showSnackBar(
            'A helymeghatározás szolgáltatás ki van kapcsolva. Kérjük, kapcsolja be!');
      }
      return;
    }

    // Ellenőrizzük a helymeghatározás engedélyeket
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showSnackBar('A helymeghatározási engedélyek megtagadva');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showSnackBar(
            'A helymeghatározási engedélyek véglegesen megtagadva. Kérjük, engedélyezze a beállításokban.');
      }
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
    });
  }

  double get _vehicleWeight =>
      double.tryParse(_weightController.text) ?? 1500.0;
  double get _wheelRadius =>
      double.tryParse(_wheelRadiusController.text) ?? 0.3;

  void _startMeasurement() async {
    if (_isMeasuring || !_locationPermissionGranted) return;

    // Ellenőrizzük, hogy van-e érvényes súly és keréksugár megadva
    if (_vehicleWeight <= 0) {
      _showSnackBar('Kérjük, adjon meg érvényes járműsúlyt!');
      return;
    }

    if (_wheelRadius <= 0) {
      _showSnackBar('Kérjük, adjon meg érvényes keréksugarat!');
      return;
    }

    setState(() {
      _isMeasuring = true;
      _horsepowerData.clear();
      _torqueData.clear();
      _measurementIndex = 0;
      _maxHorsepower = 0.0;
      _maxTorque = 0.0;
      _speed = 0.0;
      _previousSpeed = 0.0;
      _acceleration = 0.0;
      _lastSpeedUpdate = null;
    });

    // Kezdeti pozíció lekérése az összehasonlításhoz
    try {
      await _getSpeed();

      _measurementTimer = Timer.periodic(_measurementInterval, (_) {
        _getSpeed();
      });
    } catch (e) {
      _stopMeasurement();
      _showSnackBar('Hiba a mérés indításakor: $e');
    }
  }

  void _stopMeasurement() {
    _measurementTimer?.cancel();
    setState(() {
      _isMeasuring = false;
    });
  }

  Future<void> _getSpeed() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        // ignore: deprecated_member_use
        timeLimit: const Duration(seconds: 2),
      );

      final DateTime now = DateTime.now();

      if (!mounted) return;

      // Sebesség m/s-ben
      final double currentSpeed = position.speed;

      // Ha van előző mérésünk, számítsuk ki a gyorsulást
      if (_lastSpeedUpdate != null) {
        final double timeDiff =
            now.difference(_lastSpeedUpdate!).inMilliseconds / 1000.0;

        if (timeDiff > 0) {
          // Gyorsulás számítása m/s² mértékegységben
          _acceleration = (currentSpeed - _previousSpeed) / timeDiff;

          // Szűrjük a kiugró értékeket, ha irreális a gyorsulás
          if (_acceleration.abs() > 15) {
            // ~1.5G maximum
            _acceleration = _previousSpeed > 0
                ? (_previousSpeed * 0.2)
                : // Előző sebesség alapján becsült érték
                0.0;
          }
        }
      }

      setState(() {
        _previousSpeed = _speed;
        _speed = currentSpeed;
        _lastSpeedUpdate = now;
      });

      _calculatePerformance();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Hiba a sebesség lekérése során: $e");
    }
  }

  void _calculatePerformance() {
    // Csak pozitív gyorsulás és sebesség esetén számolunk
    if (_acceleration <= 0 || _speed <= 0) return;

    final double weight = _vehicleWeight; // kg
    final double wheelRadius = _wheelRadius; // méter

    // 1. Fizikai erő számítása (Newton) - F = m * a
    final double force = weight * _acceleration;

    // 2. Nyomaték számítása (Nm) - T = F * r
    final double calcTorque = force * wheelRadius;

    // 3. Szögsebesség (rad/s) - ω = v / r
    final double angularVelocity = _speed / wheelRadius;

    // 4. Mechanikai teljesítmény (Watt) - P = T * ω
    final double powerWatts = calcTorque * angularVelocity;

    // 5. Átváltás lóerőre (1 LE = 735.5 Watt)
    final double hp = powerWatts / 735.5;

    setState(() {
      // Mérési adatok hozzáadása a grafikonhoz
      _horsepowerData.add(FlSpot(_measurementIndex.toDouble(), hp));
      _torqueData.add(FlSpot(_measurementIndex.toDouble(), calcTorque));
      _measurementIndex++;

      // Maximumok frissítése
      if (hp > _maxHorsepower) _maxHorsepower = hp;
      if (calcTorque > _maxTorque) _maxTorque = calcTorque;

      // Mérés automatikus leállítása, ha a teljesítmény és a nyomaték is csökken
      // és már van legalább 10 mérési pont
      if (_horsepowerData.length > 10 &&
          hp < _maxHorsepower * 0.7 &&
          calcTorque < _maxTorque * 0.7) {
        _stopMeasurement();
      }
    });
  }

  // Sebesség átváltása m/s-ről km/h-ra
  double _getSpeedKmh() {
    // 1 m/s = 3.6 km/h
    return _speed * 3.6;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildChart() {
    return _horsepowerData.isEmpty
        ? const Center(
            child: Text(
              'Indítsa el a mérést a grafikon megjelenítéséhez',
              style: TextStyle(color: Colors.white70),
            ),
          )
        : LineChart(
            LineChartData(
              minY: 0,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final bool isHorsepower = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isHorsepower ? "Lóerő" : "Nyomaték"}: ${spot.y.toStringAsFixed(1)} ${isHorsepower ? "LE" : "Nm"}',
                        TextStyle(
                          color: isHorsepower ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _horsepowerData,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.greenAccent],
                  ),
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        // ignore: deprecated_member_use
                        Colors.green.withOpacity(0.3),
                        // ignore: deprecated_member_use
                        Colors.green.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: _torqueData,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.orangeAccent],
                  ),
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        // ignore: deprecated_member_use
                        Colors.orange.withOpacity(0.3),
                        // ignore: deprecated_member_use
                        Colors.orange.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Mérési pont',
                    style: TextStyle(color: Colors.white70),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.white24),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white10,
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.white10,
                  strokeWidth: 1,
                ),
              ),
            ),
          );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Lóerő (LE)', Colors.green),
        const SizedBox(width: 24),
        _legendItem('Nyomaték (Nm)', Colors.orange),
      ],
    );
  }

  Widget _legendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _measurementTimer?.cancel();
    _weightController.dispose();
    _wheelRadiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Teljesítménymérés",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Konfiguráció panel
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Súly beállítás
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Jármű súlya (kg)",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            hintText: "Pl.: 1500",
                            filled: true,
                            fillColor: Colors.grey.shade900,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Kerék sugár beállítás
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kerék sugara (m)",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _wheelRadiusController,
                          decoration: InputDecoration(
                            hintText: "Pl.: 0.3",
                            filled: true,
                            fillColor: Colors.grey.shade900,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mérés vezérlők
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isMeasuring ? null : _startMeasurement,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Mérés indítása"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isMeasuring ? _stopMeasurement : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("Leállítás"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              // Jelenlegi sebesség kijelzése
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Aktuális sebesség:",
                      style: TextStyle(color: Colors.white),
                    ),
                    RichText(
                      text: TextSpan(
                        text: _speed.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        children: [
                          const TextSpan(
                            text: " m/s",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          const TextSpan(
                            text: " (≈ ",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          TextSpan(
                            text: _getSpeedKmh().toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const TextSpan(
                            text: " km/h)",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Grafikon terület
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    // ignore: deprecated_member_use
                    border: Border.all(
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(0.3), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildLegend(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildChart()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Maximális értékek panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  // ignore: deprecated_member_use
                  border:
                      // ignore: deprecated_member_use
                      Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    const Text(
                      "MAXIMÁLIS ÉRTÉKEK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Max Lóerő:",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        Text(
                          "${_maxHorsepower.toStringAsFixed(1)} LE",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Max Nyomaték:",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        Text(
                          "${_maxTorque.toStringAsFixed(1)} Nm",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
