// Motracker — Auth Provider

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  String? _userPhoto;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhoto => _userPhoto;

  /// Initialize auth state on app start
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    _isLoggedIn = await _authService.initialize();
    
    if (_isLoggedIn) {
      _userEmail = _authService.userEmail;
      _userName = _authService.userName;
      _userPhoto = _authService.userPhoto;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();
    
    _isLoggedIn = await _authService.signIn();
    
    if (_isLoggedIn) {
      _userEmail = _authService.userEmail;
      _userName = _authService.userName;
      _userPhoto = _authService.userPhoto;
    }
    
    _isLoading = false;
    notifyListeners();
    
    return _isLoggedIn;
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.signOut();
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _userPhoto = null;
    
    _isLoading = false;
    notifyListeners();
  }
}
