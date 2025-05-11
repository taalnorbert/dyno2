import 'package:dyno2/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/speed_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CompetitionsPage extends StatefulWidget {
  const CompetitionsPage({super.key});

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  final SpeedProvider _speedProvider = SpeedProvider();
  int _selectedLeaderboardType = 0; // 0: 0-100, 1: 100-200, 2: 1/4 mérföld
  bool _showPersonalResults = false;
  List<Map<String, dynamic>>? _personalMeasurements;
  List<Map<String, dynamic>>? _dailyTopMeasurements;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _measurementsSubscription;

  // Aktív adatok kiválasztása
  List<Map<String, dynamic>>? get _activeData {
    if (_isLoading) {
      return null;
    }
    if (_showPersonalResults) {
      return _personalMeasurements;
    } else {
      return _dailyTopMeasurements;
    }
  }

  String _getLeaderboardTitle() {
    String baseTitle;
    switch (_selectedLeaderboardType) {
      case 0:
        baseTitle = _speedProvider.isKmh ? "0-100 km/h" : "0-60 mph";
        break;
      case 1:
        baseTitle = _speedProvider.isKmh ? "100-200 km/h" : "60-120 mph";
        break;
      case 2:
        baseTitle = "1/4 Mile";
        break;
      default:
        baseTitle = "Competitions";
    }

    return baseTitle;
  }

  String _getTimeUnit() {
    return _selectedLeaderboardType == 2 ? "sec" : "mp";
  }

  @override
  void initState() {
    super.initState();
    // Add listener to update UI when unit changes
    _speedProvider.addListener(() {
      if (mounted) setState(() {});
    });
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    _speedProvider.removeListener(() {
      if (mounted) setState(() {});
    });
    _measurementsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeUpdates() {
    _startListeningToMeasurements();
  }

  void _startListeningToMeasurements() {
    String measurementType;
    switch (_selectedLeaderboardType) {
      case 0:
        measurementType = 'zero-to-hundred';
        break;
      case 1:
        measurementType = 'hundred-to-twohundred';
        break;
      case 2:
        measurementType = 'quarter-mile';
        break;
      default:
        measurementType = 'zero-to-hundred';
    }

    // Cancel any existing subscription
    _measurementsSubscription?.cancel();

    // Set up new real-time listener based on view type
    if (_showPersonalResults) {
      // Listen to personal measurements - Ezt hagyjuk változatlanul
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        _measurementsSubscription = FirebaseFirestore.instance
            .collection('measurements')
            .where('userId', isEqualTo: currentUser.uid)
            .where('type', isEqualTo: measurementType)
            .orderBy('date', descending: true)
            .snapshots()
            .listen((snapshot) {
          if (!mounted) return;

          final measurements = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'username': 'Te',
              'car': data['car'] ?? 'Unknown Car',
              'time': (data['time'] as num).toDouble(),
              'date': data['date'],
            };
          }).toList();

          setState(() {
            _personalMeasurements = measurements;
            _isLoading = false;
          });
        });
      }
    } else {
      // Listen to daily top measurements - Itt kell a mai napra szűrni
      // Számítsuk ki a mai nap kezdetét és végét
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      // Firestore timestamp-ekre konvertálás
      final startTimestamp = Timestamp.fromDate(startOfDay);
      final endTimestamp = Timestamp.fromDate(endOfDay);

      _measurementsSubscription = FirebaseFirestore.instance
          .collection('measurements')
          .where('type', isEqualTo: measurementType)
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp)
          .snapshots()
          .listen((snapshot) {
        _processMeasurementsSnapshot(snapshot);
      });
    }
  }

  void _processMeasurementsSnapshot(QuerySnapshot snapshot) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, Map<String, dynamic>> bestByUser = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String;
        final time = (data['time'] as num).toDouble();

        // Try to get user data
        try {
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get()
              .then((userDoc) {
            if (userDoc.exists) {
              final userData = userDoc.data();
              String username =
                  userData?['nickname'] ?? userData?['email'] ?? 'Unknown User';

              // Only update if this is better than existing result or first result
              if (!bestByUser.containsKey(userId) ||
                  time < bestByUser[userId]!['time']) {
                final bool isCurrentUser =
                    userId == AuthService().currentUser?.uid;

                if (mounted) {
                  setState(() {
                    bestByUser[userId] = {
                      'username': isCurrentUser ? 'Te' : username,
                      'car': data['car'] ?? 'Unknown Car',
                      'time': time,
                      'isCurrentUser': isCurrentUser,
                    };

                    // Update the daily top measurements
                    final List<Map<String, dynamic>> topMeasurements =
                        bestByUser.values.toList()
                          ..sort((a, b) => (a['time'] as double)
                              .compareTo(b['time'] as double));
                    _dailyTopMeasurements = topMeasurements.take(50).toList();
                  });
                }
              }
            }
          });
        } catch (e) {
          // ignore: avoid_print
          print('Error fetching user data: $e');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error processing measurements: $e');
      setState(() {
        _dailyTopMeasurements = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPersonalMeasurements() async {
    setState(() {
      _isLoading = true;
      _personalMeasurements = []; // Initialize to empty array before loading
    });

    String measurementType;
    switch (_selectedLeaderboardType) {
      case 0:
        measurementType = 'zero-to-hundred';
        break;
      case 1:
        measurementType = 'hundred-to-twohundred';
        break;
      case 2:
        measurementType = 'quarter-mile';
        break;
      default:
        measurementType = 'zero-to-hundred';
    }

    try {
      // Debug print the current user ID
      final currentUser = AuthService().currentUser;
      // ignore: avoid_print
      print('Current user ID: ${currentUser?.uid}');

      // Debug print the measurement type we're looking for
      // ignore: avoid_print
      print('Loading measurements for type: $measurementType');

      final measurements =
          await AuthService().getUserMeasurements(measurementType);

      // Debug print the results
      // ignore: avoid_print
      print('Received ${measurements.length} measurements from AuthService');
      for (var m in measurements) {
        // ignore: avoid_print
        print('Measurement data: $m');
      }

      // Update state with the measurements, even if empty
      setState(() {
        _personalMeasurements = measurements;
        _isLoading = false;
      });

      // For debugging, let's also print the current state of _activeData
      // ignore: avoid_print
      print('Active data length after loading: ${_activeData?.length ?? 0}');
    } catch (e) {
      // ignore: avoid_print
      print('Error loading measurements: $e');
      setState(() {
        _personalMeasurements = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getLeaderboardTitle(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
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

          // Saját / Napi legjobbak választó
          Container(
            margin: EdgeInsets.only(bottom: 10, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDataSourceButton(false, "Napi legjobbak"),
                _buildDataSourceButton(true, "Saját mérések"),
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
                        Expanded(
                          flex: 5,
                          child: Text(
                            "Felhasználó",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            "Autó",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Idő",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _buildLeaderboard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(int index, String title) {
    final isSelected = _selectedLeaderboardType == index;

    String buttonText;
    switch (index) {
      case 0:
        buttonText = _speedProvider.isKmh ? "0-100" : "0-60";
        break;
      case 1:
        buttonText = _speedProvider.isKmh ? "100-200" : "60-120";
        break;
      case 2:
        buttonText = "1/4 Mile";
        break;
      default:
        buttonText = title;
    }

    return Expanded(
      child: InkWell(
        onTap: () async {
          // Töröljük az előző lekérdezést
          await _measurementsSubscription?.cancel();

          setState(() {
            _selectedLeaderboardType = index;
            _isLoading = true; // Mutassuk a betöltést
          });

          // Várjunk egy kis időt, hogy biztosan törlődjön az előző lekérdezés
          await Future.delayed(Duration(milliseconds: 100));

          // Indítsuk az új lekérdezést
          if (_showPersonalResults) {
            await _loadPersonalMeasurements();
          } else {
            _startListeningToMeasurements();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            buttonText,
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

  Widget _buildDataSourceButton(bool isPersonal, String title) {
    final isSelected = _showPersonalResults == isPersonal;
    final currentUser = AuthService().currentUser;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (isPersonal && currentUser == null) {
            // Ha a saját mérésekre kattint és nincs bejelentkezve
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    'Bejelentkezés szükséges',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    'A saját mérések megtekintéséhez jelentkezz be!',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Mégse',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/login');
                      },
                      child: Text(
                        'Bejelentkezés',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ),
                  ],
                );
              },
            );
            return;
          }

          setState(() {
            _showPersonalResults = isPersonal;
          });
          _startListeningToMeasurements();
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
    // Első három helyezett színei - csak a napi legjobbaknál
    Color? rankColor;
    Color bgColor = Colors.transparent;

    if (!_showPersonalResults) {
      if (index == 0) {
        rankColor = Colors.amber; // Arany
      } else if (index == 1) {
        rankColor = Colors.grey[400]; // Ezüst
      } else if (index == 2) {
        rankColor = Colors.brown[300]; // Bronz
      }

      // Ha ez a bejelentkezett felhasználó sora
      if (item['username'] == 'Te') {
        // ignore: deprecated_member_use
        bgColor = Colors.amber.withOpacity(0.2);
      } else {
        bgColor =
            // ignore: deprecated_member_use
            index % 2 == 0 ? Colors.black.withOpacity(0.3) : Colors.transparent;
      }
    } else {
      bgColor =
          // ignore: deprecated_member_use
          index % 2 == 0 ? Colors.black.withOpacity(0.3) : Colors.transparent;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Helyezés vagy mérés száma
          SizedBox(
            width: 30,
            child: Text(
              "${index + 1}.",
              style: TextStyle(
                color: rankColor ?? Colors.white,
                fontWeight:
                    rankColor != null ? FontWeight.bold : FontWeight.normal,
                fontSize: rankColor != null ? 16 : 14,
              ),
            ),
          ),

          // Felhasználói név
          Expanded(
            flex: 5,
            child: Text(
              item['username'],
              style: TextStyle(
                color: _showPersonalResults || item['username'] == 'Te'
                    ? Colors.amber
                    : Colors.white,
                fontWeight: rankColor != null ||
                        _showPersonalResults ||
                        item['username'] == 'Te'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),

          // Autó típus
          Expanded(
            flex: 5,
            child: Text(
              item['car'],
              style: TextStyle(
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

          // Idő
          Container(
            width: 80,
            alignment: Alignment.centerRight,
            child: Text(
              "${item['time'].toStringAsFixed(1)} ${_getTimeUnit()}",
              textAlign: TextAlign.right,
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

  Widget _buildLeaderboard() {
    if (_isLoading || _activeData == null) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.amber,
        ),
      );
    }

    final data = _activeData!;
    if (data.isEmpty) {
      return Center(
        child: Text(
          _showPersonalResults
              ? "Még nincsenek mérési eredményeid"
              : "Ma még nem születtek eredmények ebben a kategóriában",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return _buildLeaderboardItem(index, item);
      },
    );
  }
}
