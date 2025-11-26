// lib/auth/auth_service.dart - UPDATED
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _pinKey = 'user_pin';
  static const String _onboardedKey = 'onboarded_status';
  
  // NEW KEYS
  static const String _securityQuestionKey = 'security_question';
  static const String _securityAnswerKey = 'security_answer';

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  // --- NEW: Security Question Logic ---
  
  Future<void> saveSecurityInfo(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_securityQuestionKey, question);
    await prefs.setString(_securityAnswerKey, answer.trim().toLowerCase()); // Store normalized
  }

  Future<String?> getSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_securityQuestionKey);
  }

  Future<bool> validateSecurityAnswer(String inputAnswer) async {
    final prefs = await SharedPreferences.getInstance();
    final storedAnswer = prefs.getString(_securityAnswerKey);
    if (storedAnswer == null) return false;
    return storedAnswer == inputAnswer.trim().toLowerCase();
  }
  // ------------------------------------

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  Future<void> setOnboarded(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, status);
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_onboardedKey);
    await prefs.remove(_securityQuestionKey);
    await prefs.remove(_securityAnswerKey);
  }
}