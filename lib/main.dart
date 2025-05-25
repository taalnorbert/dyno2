import 'package:dyno2/routes/router_config.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:dyno2/speed_meter/Navbar/Pages/home.dart';
import 'package:dyno2/widgets/main_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dyno2/providers/language_provider.dart';
import 'package:dyno2/localization/app_localizations_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final languageProvider = LanguageProvider();

  // Initialize language from stored preferences
  final savedLanguage = prefs.getString('languageCode');
  if (savedLanguage != null) {
    await languageProvider.setLanguage(savedLanguage);
  }

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LanguageProvider _languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _languageProvider.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageProvider.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Speed cucc',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      locale: Locale(_languageProvider.languageCode),
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('hu', ''), // Hungarian
        Locale('de', ''), // German
      ],
      localizationsDelegates: [
        // No const keyword here to avoid errors
        const AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainView();
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
