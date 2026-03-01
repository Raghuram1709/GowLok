import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  LocaleController([Locale? initial]) {
    _locale = initial ?? const Locale('en');
  }

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  void setLocale(String code) {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
  }

  static const List<Locale> supportedLocales = [
    Locale('en'), Locale('te'), Locale('hi'), Locale('ta'), Locale('kn'),
    Locale('ml'), Locale('bn'), Locale('mr'), Locale('gu'), Locale('pa'),
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'te': 'తెలుగు',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
    'bn': 'বাংলা',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'pa': 'ਪੰਜਾਬੀ',
  };
}
