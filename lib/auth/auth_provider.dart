// lib/auth/auth_provider.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:gym/auth/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  bool _isAuthenticated = false;
  bool _isOnboarded = false;
  bool _isLoading = true;

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
  }

  // UPDATED: Now accepts security question and answer
  Future<bool> setPin(String pin, {String? question, String? answer}) async {
    try {
      await _authService.savePin(pin);
      
      // Save security info if provided
      if (question != null && answer != null) {
        await _authService.saveSecurityInfo(question, answer);
      }

      await _authService.setOnboarded(true);
      _isOnboarded = true;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error setting PIN: $e');
      return false;
    }
  }

  // NEW: Get the saved question to show user
  Future<String?> getSecurityQuestion() async {
    return await _authService.getSecurityQuestion();
  }

  // NEW: Validate answer
  Future<bool> recoverAccount(String answer) async {
    return await _authService.validateSecurityAnswer(answer);
  }

  Future<void> resetAuth() async {
    await _authService.clearAuthData();
    _isOnboarded = false;
    _isAuthenticated = false;
    notifyListeners();
  }
}