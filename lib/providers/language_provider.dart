import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;

  static const String _languageCodeKey = 'languageCode';
  String _languageCode = 'hu'; // Default is Hungarian

  LanguageProvider._internal() {
    _initializePreferences();
  }
  String get languageCode => _languageCode;
  bool get isHungarian => _languageCode == 'hu';
  bool get isGerman => _languageCode == 'de';

  Future<void> _initializePreferences() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await _loadLanguage();
    } catch (e) {
      _languageCode = 'hu'; // Fallback to default
    }
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _languageCode = prefs.getString(_languageCodeKey) ?? 'hu';
      notifyListeners();
    } catch (e) {
      _languageCode = 'hu'; // Fallback to default
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
    notifyListeners();
  }
}
