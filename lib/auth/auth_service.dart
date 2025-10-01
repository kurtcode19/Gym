// lib/auth/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _pinKey = 'user_pin';
  static const String _onboardedKey = 'onboarded_status';

  // Save the user's PIN
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  // Retrieve the user's PIN
  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  // Check if the user has completed onboarding
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  // Mark onboarding as complete
  Future<void> setOnboarded(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, status);
  }

  // Clear all authentication data (for logout/reset)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_onboardedKey);
  }
}