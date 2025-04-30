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
import 'package:dyno2/providers/speed_provider.dart';
import 'package:dyno2/speed_meter/widgets/location_disabled_screen.dart';

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
  // Change initial index to 2 since Home is at index 2
  int bottomNavigationIndex = 2;
  // Initialize PageController with initial page 2
  final PageController pageController = PageController(initialPage: 2);
  final SpeedProvider _speedProvider = SpeedProvider();

  void _showNoGpsWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nincs GPS jel! Várj a jel megszerzésére.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMeasurementDialog() {
    if (!mounted || !_speedProvider.hasGpsSignal) {
      _showNoGpsWarning();
      return;
    }

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
                onTap: () {
                  Navigator.pop(dialogContext);
                  if (_speedProvider.currentSpeed > 5.0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('A jármű mozgásban van! A méréshez állj meg!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ZeroToHundred()),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text(
                  '100-200',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  if (_speedProvider.currentSpeed < 95 ||
                      _speedProvider.currentSpeed > 105) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_speedProvider.currentSpeed < 95
                            ? 'A sebesség túl alacsony! A méréshez érj el 100 km/h-t!'
                            : 'A sebesség túl magas! A méréshez lassíts 100 km/h-ra!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HundredToTwoHundred()),
                    );
                  }
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
    return ListenableBuilder(
      listenable: _speedProvider,
      builder: (context, _) {
        if (!_speedProvider.isLocationServiceEnabled) {
          return const LocationDisabledScreen();
        }

        return Scaffold(
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.black,
            indicatorColor: Colors.transparent,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.speed_outlined,
                  color: bottomNavigationIndex == 0
                      ? Colors.redAccent
                      : Colors.grey,
                ),
                label: 'Measure',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.leaderboard,
                  color: bottomNavigationIndex == 1
                      ? Colors.redAccent
                      : Colors.grey,
                ),
                label: 'Verseny',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.home,
                  color: bottomNavigationIndex == 2
                      ? Colors.redAccent
                      : Colors.grey,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.speed,
                  color: bottomNavigationIndex == 3
                      ? Colors.redAccent
                      : Colors.grey,
                ),
                label: 'Dyno',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.timer,
                  color: bottomNavigationIndex == 4
                      ? Colors.redAccent
                      : Colors.grey,
                ),
                label: 'Laptime',
              ),
            ],
            selectedIndex: bottomNavigationIndex,
            height: 80,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            onDestinationSelected: (index) {
              if (!_speedProvider.hasGpsSignal &&
                  (index == 0 || index == 3 || index == 4)) {
                _showNoGpsWarning();
                return;
              }

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
              const HomePage(),
              const CompetitionsPage(),
              const HomePage(),
              const dynoscreen(),
              const LapTimeScreen(),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
