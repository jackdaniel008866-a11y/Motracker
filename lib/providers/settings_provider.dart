import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class SettingsProvider with ChangeNotifier {
  String _currencySymbol = '₹';
  bool _isLoading = true;

  String get currencySymbol => _currencySymbol;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('currencySymbol') ?? '₹';
    AppConstants.currencySymbol = _currencySymbol;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    AppConstants.currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', symbol);
    notifyListeners();
  }
}
