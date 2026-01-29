import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  final SharedPreferences _prefs;

  LocaleProvider(this._prefs) {
    _loadLocale();
  }

  Locale? get locale => _locale;

  void _loadLocale() {
    final languageCode = _prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'id'].contains(locale.languageCode)) return;

    _locale = locale;
    await _prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    notifyListeners();
  }
}
