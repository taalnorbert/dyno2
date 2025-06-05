import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/speed_provider.dart'; // Add this import if not already present

class DynoScreen extends StatefulWidget {
  const DynoScreen({super.key});

  @override
  State<DynoScreen> createState() => _DynoScreenState();
}

class _DynoScreenState extends State<DynoScreen>
    with SingleTickerProviderStateMixin {
  // Use SpeedProvider instead of direct GPS access
  final SpeedProvider _speedProvider = SpeedProvider();
  final TextEditingController _weightController =
      TextEditingController(text: '1100');

  // Mérési értékek
  double _acceleration = 0.0;
  double _maxHorsepower = 0.0;
  double _finalHorsepower = 0.0;
  DateTime? _lastSpeedUpdate;
  double _previousSpeed = 0.0;

  // Konfiguráció
  static const Duration _measurementInterval = Duration(milliseconds: 200);

  // Grafikon adatok
  final List<FlSpot> _horsepowerData = [];
  final List<double> _speedPoints = [];
  int _measurementIndex = 0;

  // Állapotkezelés
  Timer? _measurementTimer;
  bool _isMeasuring = false;
  bool _locationPermissionGranted = false;

  // Animációk
  AnimationController? _animationController;
  Animation<double>? _chartAnimation;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();

    // Add listener to SpeedProvider to get speed updates
    _speedProvider.addListener(_onSpeedChanged);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _chartAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutCubic,
    );

    _animationsInitialized = true;
  }

  // Add this method to handle SpeedProvider updates
  void _onSpeedChanged() {
    if (_isMeasuring && _lastSpeedUpdate != null) {
      final double currentSpeed = _speedProvider.isKmh
          ? _speedProvider.currentSpeed / 3.6 // Convert km/h to m/s
          : _speedProvider.currentSpeed / 2.237; // Convert mph to m/s

      final DateTime now = DateTime.now();
      final double timeDiff =
          now.difference(_lastSpeedUpdate!).inMilliseconds / 1000.0;

      if (timeDiff > 0) {
        _acceleration = (currentSpeed - _previousSpeed) / timeDiff;

        // Filter outliers
        if (_acceleration.abs() > 12) {
          _acceleration = _previousSpeed > 0 ? (_previousSpeed * 0.1) : 0.0;
        }

        // Add data point if measuring
        if (_isMeasuring && timeDiff < 5.0) {
          _addHorsepowerDataPoint(currentSpeed, _acceleration);
        }
      }

      _previousSpeed = currentSpeed;
      _lastSpeedUpdate = now;
    }

    // Force UI update
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showSnackBar(
            'A helymeghatározás szolgáltatás ki van kapcsolva. Kérjük, kapcsolja be!');
      }
      return;
    }

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
      double.tryParse(_weightController.text) ?? 1100.0;

  void _startMeasurement() async {
    if (_isMeasuring || !_locationPermissionGranted) {
      _showSnackBar(_locationPermissionGranted
          ? 'Mérés már folyamatban van'
          : 'Helymeghatározási engedély szükséges');
      return;
    }

    if (_vehicleWeight <= 0) {
      _showSnackBar('Kérjük, adjon meg érvényes járműsúlyt!');
      return;
    }

    setState(() {
      _isMeasuring = true;
      _horsepowerData.clear();
      _speedPoints.clear();
      _measurementIndex = 0;
      _maxHorsepower = 0.0;
      _finalHorsepower = 0.0;
      _previousSpeed = 0.0;
      _acceleration = 0.0;
      _lastSpeedUpdate = DateTime.now(); // Initialize with current time
    });

    // Reset and start animation
    if (_animationsInitialized) {
      _animationController!.reset();
      _animationController!.forward();
    }

    try {
      // Show user that measurement is starting
      _showSnackBar('Mérés indítása... GPS jelek figyelése');

      // Set up the timer for updating UI and recording data
      _measurementTimer = Timer.periodic(_measurementInterval, (_) {
        // We don't need to call _getSpeed() as SpeedProvider already updates the speed
        // Just force a UI update
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      _stopMeasurement();
      _showSnackBar('Hiba a mérés indításakor');
    }
  }

  void _stopMeasurement() {
    _measurementTimer?.cancel();
    setState(() {
      _isMeasuring = false;
      _finalHorsepower = _maxHorsepower;
    });

    // Play reverse animation
    if (_animationsInitialized) {
      _animationController!.reverse();
    }
  }

  // Create a separate method to handle data point addition with relaxed constraints for testing
  void _addHorsepowerDataPoint(double currentSpeed, double acceleration) {
    final double weight = _vehicleWeight;
    final double speedKmh = _speedProvider.isKmh
        ? currentSpeed * 3.6 // Convert m/s to km/h
        : currentSpeed * 2.237; // Convert m/s to mph

    // Calculate forces
    double dragForce = _calculateDragForce(speedKmh);
    double rollingResistance = _calculateRollingResistance(weight);
    double totalResistance = dragForce + rollingResistance;
    double accelerationForce = weight * acceleration;
    double totalForce = accelerationForce + totalResistance;

    // Calculate power
    double wheelPowerWatts = totalForce * currentSpeed;
    double enginePowerWatts = wheelPowerWatts / 0.85;
    double hp = enginePowerWatts / 735.5;
    hp = _applyDynoCurveCorrection(hp, speedKmh);

    // For debugging, add a minimum value
    if (hp < 0) hp = 0;

    setState(() {
      _horsepowerData.add(FlSpot(speedKmh, hp));
      _speedPoints.add(speedKmh);
      _measurementIndex++;

      if (hp > _maxHorsepower) {
        _maxHorsepower = hp;
        _finalHorsepower = hp;
      }

      // Auto-stop conditions
      if ((_horsepowerData.length > 15 && hp < _maxHorsepower * 0.6) ||
          speedKmh > (_speedProvider.isKmh ? 180 : 112)) {
        // 180 km/h or 112 mph
        _stopMeasurement();
      }
    });
  }

  // Update simulation to use the current unit system
  void _startSimulatedMeasurement() {
    if (_isMeasuring) return;

    setState(() {
      _isMeasuring = true;
      _horsepowerData.clear();
      _speedPoints.clear();
      _measurementIndex = 0;
      _maxHorsepower = 0.0;
      _finalHorsepower = 0.0;
    });

    // Reset and start animation
    if (_animationsInitialized) {
      _animationController!.reset();
      _animationController!.forward();
    }

    // Simulate acceleration
    double simulatedSpeed = 0.0;
    double maxHp = _vehicleWeight * 0.2; // ~200 HP for a 1000kg car
    double maxSpeed =
        _speedProvider.isKmh ? 200.0 : 124.0; // 200 km/h or 124 mph

    _measurementTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      // Simulated acceleration
      simulatedSpeed +=
          _speedProvider.isKmh ? 3.0 : 1.86; // 3 km/h or 1.86 mph increment

      if (simulatedSpeed > maxSpeed) {
        _stopMeasurement();
        return;
      }

      // Simulated horsepower curve
      double simulatedHp;
      double peakSpeed =
          _speedProvider.isKmh ? 120.0 : 74.5; // 120 km/h or 74.5 mph

      if (simulatedSpeed < peakSpeed * 0.67) {
        simulatedHp = maxHp * (simulatedSpeed / peakSpeed);
      } else if (simulatedSpeed < peakSpeed) {
        simulatedHp =
            maxHp * (1.0 - (simulatedSpeed - peakSpeed * 0.67) * 0.005);
      } else {
        simulatedHp = maxHp * (0.8 - (simulatedSpeed - peakSpeed) * 0.002);
      }

      setState(() {
        _horsepowerData.add(FlSpot(simulatedSpeed, simulatedHp));
        _speedPoints.add(simulatedSpeed);
        _measurementIndex++;

        if (simulatedHp > _maxHorsepower) {
          _maxHorsepower = simulatedHp;
          _finalHorsepower = simulatedHp;
        }
      });
    });
  }

  // Adjust formulas based on unit system
  double _calculateDragForce(double speed) {
    double speedMs = _speedProvider.isKmh
        ? speed / 3.6 // Convert km/h to m/s
        : speed / 2.237; // Convert mph to m/s

    // Cd * A * rho * v^2 / 2
    // Átlagos Cd = 0.32, A = 2.2 m², rho = 1.225 kg/m³
    return 0.32 * 2.2 * 1.225 * speedMs * speedMs / 2;
  }

  double _getSpeedInCurrentUnit() {
    return _speedProvider.getCurrentSpeed();
  }

  // Add the missing _showSnackBar method
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Add the missing _calculateRollingResistance method
  double _calculateRollingResistance(double weight) {
    // Cr * m * g (Cr = 0.012 átlag személyautóhoz)
    return 0.012 * weight * 9.81;
  }

  // Add the missing _applyDynoCurveCorrection method
  double _applyDynoCurveCorrection(double hp, double speedKmh) {
    // Valósághű motor karakterisztika szimuláció
    // A legtöbb motor 4000-6000 rpm között adja a maximum teljesítményt
    if (speedKmh < 20) {
      // Alacsony fordulatszám - csökkentett teljesítmény
      return hp * (0.6 + (speedKmh / 20) * 0.4);
    } else if (speedKmh > 140) {
      // Magas fordulatszám - teljesítmény csökkenés
      double reduction = (speedKmh - 140) / 60; // 60 km/h range
      return hp * (1.0 - math.min(reduction * 0.3, 0.5));
    }
    return hp;
  }

  // Add the missing _buildChart method
  Widget _buildChart() {
    // If data is empty, show placeholder message
    if (_horsepowerData.isEmpty) {
      return const Center(
        child: Text(
          'Indítsa el a mérést a dyno görbe megjelenítéséhez',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Check if animations are initialized
    if (!_animationsInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Otherwise, build the actual chart with animation
    return AnimatedBuilder(
        animation: _chartAnimation!,
        builder: (context, child) {
          // We'll only show a portion of data points based on animation progress
          final visibleCount =
              (_horsepowerData.length * _chartAnimation!.value).ceil();
          final visibleData = _horsepowerData.sublist(
              0, math.min(visibleCount, _horsepowerData.length));

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: _maxHorsepower > 0 ? _maxHorsepower * 1.2 : 100,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        'Sebesség: ${spot.x.toStringAsFixed(0)} ${_speedProvider.isKmh ? 'km/h' : 'mph'}\nTeljesítmény: ${spot.y.toStringAsFixed(1)} LE',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: visibleData,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.orange, Colors.yellow],
                  ),
                  barWidth: 4,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      // Kiemeljük a maximum pontot
                      if (spot.y >= _maxHorsepower * 0.95) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.red,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 2,
                        color: Colors.orange,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withAlpha(76), // 0.3 opacity
                        Colors.orange.withAlpha(0), // 0.0 opacity
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Lóerő (LE)',
                    style: TextStyle(color: Colors.white70),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    'Sebesség (${_speedProvider.isKmh ? 'km/h' : 'mph'})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
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
                horizontalInterval: 20,
                verticalInterval: 20,
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
        });
  }

  @override
  void dispose() {
    _measurementTimer?.cancel();
    _weightController.dispose();
    _animationController?.dispose();
    _speedProvider.removeListener(_onSpeedChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Dyno Teljesítménymérés",
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
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isMeasuring ? 0.6 : 1.0,
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
                      enabled: !_isMeasuring,
                      decoration: InputDecoration(
                        hintText: "Pl.: 1100 (Peugeot 206)",
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
              const SizedBox(height: 16),

              // Mérés vezérlők
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isMeasuring ? null : _startMeasurement,
                      icon: _isMeasuring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.speed),
                      label: const Text("Dyno Mérés Indítása"),
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
                    onPressed: _isMeasuring ? null : _startSimulatedMeasurement,
                    icon: _isMeasuring
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_graph),
                    label: const Text("Szimuláció"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isMeasuring
                      ? [
                          BoxShadow(
                            color: Colors.blue.withAlpha(40),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Aktuális sebesség:",
                          style: TextStyle(color: Colors.white),
                        ),
                        if (_isMeasuring) // Only show this when measuring
                          Text(
                            "Méréspontok: $_measurementIndex",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(
                        begin: 0,
                        end: _getSpeedInCurrentUnit(),
                      ),
                      builder: (context, value, child) => Text(
                        "${value.toStringAsFixed(1)} ${_speedProvider.isKmh ? 'km/h' : 'mph'}",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // GPS állapot kijelzése
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _speedProvider.hasGpsSignal
                      ? Colors.green.withAlpha(51)
                      : Colors.red.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _speedProvider.hasGpsSignal
                        ? Colors.green.withAlpha(76)
                        : Colors.red.withAlpha(76),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _speedProvider.hasGpsSignal
                          ? Icons.gps_fixed
                          : Icons.gps_off,
                      color: _speedProvider.hasGpsSignal
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _speedProvider.hasGpsSignal
                          ? "GPS jel aktív"
                          : "GPS jel nem található",
                      style: TextStyle(
                        color: _speedProvider.hasGpsSignal
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // Grafikon terület
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.orange.withAlpha(76), // 0.3 opacity
                        width: 2),
                    boxShadow: _isMeasuring && _horsepowerData.isNotEmpty
                        ? [
                            BoxShadow(
                              color: Colors.orange.withAlpha(51), // 0.2 opacity
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "DYNO TELJESÍTMÉNY GÖRBE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildChart()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Eredmények panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.green.withAlpha(76), // 0.3 opacity
                      width: 2),
                  boxShadow: _finalHorsepower > 0
                      ? [
                          BoxShadow(
                            color: Colors.green.withAlpha(51), // 0.2 opacity
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    const Text(
                      "BECSÜLT TELJESÍTMÉNY",
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
                          "Maximális teljesítmény:",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(
                            begin: 0,
                            end: _finalHorsepower > 0
                                ? _finalHorsepower
                                : _maxHorsepower,
                          ),
                          builder: (context, value, child) => Text(
                            "${value.toStringAsFixed(1)} LE",
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Súly/teljesítmény:",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(
                            begin: 0,
                            end: _maxHorsepower > 0
                                ? (_vehicleWeight / _maxHorsepower)
                                : 0,
                          ),
                          builder: (context, value, child) => Text(
                            _maxHorsepower > 0
                                ? "${value.toStringAsFixed(1)} kg/LE"
                                : "-- kg/LE",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
