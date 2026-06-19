import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kTheme = 'color_theme';
  static const _kWeightUnit = 'weight_unit';
  static const _kZipcode = 'zipcode';
  static const _kPatientName = 'patient_name';

  AppColorTheme _colorTheme = AppColorTheme.dustyBlue;
  String _weightUnit = 'lbs';
  String _zipcode = '';
  String _patientName = '';

  AppColorTheme get colorTheme => _colorTheme;
  String get weightUnit => _weightUnit;
  String get zipcode => _zipcode;
  String get patientName => _patientName;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _colorTheme = AppColorThemeExtension.fromDbValue(
        prefs.getString(_kTheme) ?? AppColorTheme.dustyBlue.dbValue);
    _weightUnit = prefs.getString(_kWeightUnit) ?? 'lbs';
    _zipcode = prefs.getString(_kZipcode) ?? '';
    _patientName = prefs.getString(_kPatientName) ?? '';
    notifyListeners();
  }

  Future<void> setColorTheme(AppColorTheme theme) async {
    _colorTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, theme.dbValue);
    notifyListeners();
  }

  Future<void> setWeightUnit(String unit) async {
    _weightUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeightUnit, unit);
    notifyListeners();
  }

  Future<void> setZipcode(String zipcode) async {
    _zipcode = zipcode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kZipcode, zipcode);
    notifyListeners();
  }

  Future<void> setPatientName(String name) async {
    _patientName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPatientName, name);
    notifyListeners();
  }
}
