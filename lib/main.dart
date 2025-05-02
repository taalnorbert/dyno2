import 'package:dyno2/routes/router_config.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:dyno2/login/login.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/home.dart';
import 'package:dyno2/widgets/main_scaffold.dart';

// Alkalmazás szövegek konstansai
class AppStrings {
  static const String lowSpeedWarningMessage = "Legalább 95km/h haladj!";
  static const String movingWarningMessage = "Mozgásban vagy!";
  static const String noGpsWarningMessage = 'Nincs GPS jel!';
  static const String chooseMeasurementTitle = 'Válassz mérést';
  static const String zeroToHundredLabel = '0-100';
  static const String hundredToTwoHundredLabel = '100-200';
}

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
    return MaterialApp.router(
      title: 'Speed cucc',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      routerConfig: router,
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
            return  MainView();
          } else {
            return  Login();
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
  @override
  Widget build(BuildContext context) {
    return const MainScaffold(
      child: HomePage(),
    );
  }
}
