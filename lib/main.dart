import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:dyno2/login/login.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/home.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/competitions.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/performance.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/laptime.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/zero_to_hundred.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/hundred_to_twohundred.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: SystemUiOverlay.values,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed cucc',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData && snapshot.data != null) {
            return const MainView();
          } else {
            return Login();
          }
        }
      },
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  MainViewState createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  int bottomNavigationIndex = 2; // Add this
  final PageController pageController = PageController(); // Add this
  double currentSpeed = 0.0;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStartListening();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    pageController.dispose(); // Add this
    super.dispose();
  }

  Future<void> _checkPermissionsAndStartListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      setState(() {
        currentSpeed = position.speed * 3.6; // Convert to km/h
      });
    });
  }

  void _showMeasurementDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Válassz mérést',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.speed_outlined, color: Colors.white),
                title: const Text(
                  '0-100',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext); // Close dialog first

                  if (currentSpeed > 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('A jármű mozgásban van! A méréshez állj meg!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ZeroToHundred(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text(
                  '100-200',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext); // Close dialog first

                  if (currentSpeed < 95 || currentSpeed > 105) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(currentSpeed < 95
                            ? 'A sebesség túl alacsony! A méréshez érj el 100 km/h-t!'
                            : 'A sebesség túl magas! A méréshez lassíts 100 km/h-ra!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HundredToTwoHundred(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: Colors.transparent,
        destinations: [
          NavigationDestination(
            icon: GestureDetector(
              onTap: _showMeasurementDialog,
              child: Icon(Icons.speed_outlined,
                  color: bottomNavigationIndex == 0
                      ? Colors.redAccent
                      : Colors.grey),
            ),
            label: 'Measure',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard,
                color: bottomNavigationIndex == 1
                    ? Colors.redAccent
                    : Colors.grey),
            label: 'Verseny',
          ),
          NavigationDestination(
            icon: Icon(Icons.home,
                color: bottomNavigationIndex == 2
                    ? Colors.redAccent
                    : Colors.grey),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed,
                color: bottomNavigationIndex == 3
                    ? Colors.redAccent
                    : Colors.grey),
            label: 'Dyno',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer,
                color: bottomNavigationIndex == 4
                    ? Colors.redAccent
                    : Colors.grey),
            label: 'Laptime',
          ),
        ],
        selectedIndex: bottomNavigationIndex,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior
            .onlyShowSelected, // Only show selected label
        onDestinationSelected: (index) {
          if (index != 0) {
            pageController.jumpToPage(index);
            setState(() {
              bottomNavigationIndex = index;
            });
          } else {
            _showMeasurementDialog();
          }
        },
      ),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const HomePage(), // Update the order of pages to match navigation
          const CompetitionsPage(),
          const HomePage(),
          const dynoscreen(),
          const LapTimeScreen(),
        ],
      ),
    );
  }
}
