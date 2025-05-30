import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;

  static const String _languageCodeKey = 'languageCode';
  String _languageCode = 'en'; // Változtatjuk az alapértelmezettet en-re
  final List<String> _supportedLanguages = ['hu', 'en', 'de'];

  LanguageProvider._internal() {
    _initializePreferences();
  }

  String get languageCode => _languageCode;
  bool get isHungarian => _languageCode == 'hu';
  bool get isGerman => _languageCode == 'de';
  bool get isEnglish => _languageCode == 'en';

  Future<void> _initializePreferences() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await _loadLanguage();
    } catch (e) {
      _setDefaultLanguage();
    }
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedLanguage = prefs.getString(_languageCodeKey);

      if (storedLanguage != null) {
        // Ha már van tárolt nyelvi beállítás, használjuk azt
        _languageCode = storedLanguage;
      } else {
        // Ha nincs tárolt beállítás, akkor használjuk a rendszer nyelvét vagy az alapértelmezettet
        _setDefaultLanguage();

        // Mentsük el az új beállítást
        await prefs.setString(_languageCodeKey, _languageCode);
      }
      notifyListeners();
    } catch (e) {
      _setDefaultLanguage();
    }
  }

  void _setDefaultLanguage() {
    // Rendszer nyelvének lekérdezése
    final locale = PlatformDispatcher.instance.locale;
    final systemLanguage = locale.languageCode;

    // Ellenőrizzük, hogy a rendszer nyelve támogatott-e
    if (_supportedLanguages.contains(systemLanguage)) {
      _languageCode = systemLanguage;
    } else {
      // Ha nem támogatott, akkor az angol az alapértelmezett
      _languageCode = 'en';
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
    notifyListeners();
  }
}
