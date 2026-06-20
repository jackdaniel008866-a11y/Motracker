// Motracker — Auth Service (Google Sign-In)

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Current user info
  String? _userEmail;
  String? _userName;
  String? _userPhoto;

  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhoto => _userPhoto;
  bool get isLoggedIn => _userEmail != null;

  /// Initialize — check if user was previously logged in
  Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;

    if (isLoggedIn) {
      _userEmail = prefs.getString(AppConstants.prefUserEmail);
      _userName = prefs.getString(AppConstants.prefUserName);
      _userPhoto = prefs.getString(AppConstants.prefUserPhoto);

      // Try silent sign in to refresh tokens
      try {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          await _saveUserInfo(account);
          return true;
        }
      } catch (_) {}

      // Even if silent sign-in fails, we still have the email
      return _userEmail != null;
    }

    return false;
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      if (kIsWeb) {
        // Mock sign-in for Web testing
        _userEmail = 'test@example.com';
        _userName = 'Web Tester';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.prefIsLoggedIn, true);
        await prefs.setString(AppConstants.prefUserEmail, _userEmail!);
        await prefs.setString(AppConstants.prefUserName, _userName!);
        return true;
      }

      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _saveUserInfo(account);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, false);
    await prefs.remove(AppConstants.prefUserEmail);
    await prefs.remove(AppConstants.prefUserName);
    await prefs.remove(AppConstants.prefUserPhoto);
    _userEmail = null;
    _userName = null;
    _userPhoto = null;
  }

  /// Save user info to SharedPreferences
  Future<void> _saveUserInfo(GoogleSignInAccount account) async {
    _userEmail = account.email;
    _userName = account.displayName;
    _userPhoto = account.photoUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setString(AppConstants.prefUserEmail, account.email);
    if (account.displayName != null) {
      await prefs.setString(AppConstants.prefUserName, account.displayName!);
    }
    if (account.photoUrl != null) {
      await prefs.setString(AppConstants.prefUserPhoto, account.photoUrl!);
    }
  }
}
