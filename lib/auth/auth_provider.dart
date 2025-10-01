// lib/auth/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:gym/auth/auth_service.dart'; // Corrected import

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  bool _isAuthenticated = false;
  bool _isOnboarded = false;
  bool _isLoading = true; // Added loading state for initial check

  AuthProvider(this._authService) {
    _checkAuthStatus();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboarded => _isOnboarded;
  bool get isLoading => _isLoading;

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    _isOnboarded = await _authService.isOnboarded();
    // If onboarded, check if a PIN exists. If so, they need to log in.
    // We don't auto-authenticate on app start for PIN-based systems.
    // _isAuthenticated will remain false initially.
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String pin) async {
    final storedPin = await _authService.getPin();
    if (storedPin == pin) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    notifyListeners();
    // No need to clear pin/onboarded status on logout, just reset auth state
  }

  Future<bool> setPin(String pin) async {
    try {
      await _authService.savePin(pin);
      await _authService.setOnboarded(true);
      _isOnboarded = true;
      _isAuthenticated = true; // Auto-authenticate after setting PIN
      notifyListeners();
      return true;
    } catch (e) {
      print('Error setting PIN: $e');
      return false;
    }
  }

  // This method would be used if there's a "Forgot PIN" or reset functionality
  Future<void> resetAuth() async {
    await _authService.clearAuthData();
    _isOnboarded = false;
    _isAuthenticated = false;
    notifyListeners();
  }
}