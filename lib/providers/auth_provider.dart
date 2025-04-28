import 'package:flutter/material.dart';
import 'package:shopease/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _userType;
  String? _token;
  String? _userId;
  DateTime? _expiryDate;
  Timer? _authTimer;

  bool get isAuthenticated => _isAuthenticated;
  String? get userType => _userType;
  String? get token => _token;

  AuthProvider() {
    // Check authentication status when provider is created
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isAuthenticated = await _apiService.isAuthenticated();
    if (_isAuthenticated) {
      final userData = await _apiService.getUserData();
      _userType = userData?['user_type'];
    }
    notifyListeners();
  }

  // Method to try auto login when the app starts
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have saved credentials
    if (!prefs.containsKey('userData')) {
      return false;
    }

    // Get the stored user data
    final userData = json.decode(prefs.getString('userData') ?? '{}')
        as Map<String, dynamic>;

    // Check if required fields exist
    if (!userData.containsKey('token') || !userData.containsKey('expiryDate')) {
      return false;
    }

    // Check for token expiration
    final expiryDate = DateTime.parse(userData['expiryDate']);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    // Auto login with stored data
    _token = userData['token'];
    _userId = userData['userId'];
    _expiryDate = expiryDate;
    _userType = userData['userType'];
    _isAuthenticated = true;

    // Set auto logout timer
    _autoLogout();

    // Notify the app that authentication state changed
    notifyListeners();

    return true;
  }

  // Helper method to save user data
  Future<void> _saveUserData({
    required String token,
    required String userId,
    required String userType,
    required DateTime expiryDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final userData = json.encode({
      'token': token,
      'userId': userId,
      'userType': userType,
      'expiryDate': expiryDate.toIso8601String(),
    });

    await prefs.setString('userData', userData);
  }

  // Auto logout based on token expiry
  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }

    if (_expiryDate != null) {
      final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
      _authTimer =
          Timer(Duration(seconds: timeToExpiry > 0 ? timeToExpiry : 0), logout);
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.loginUser(email, password);
      _isAuthenticated = true;
      _userType = response['user']?['user_type'];
      _token = response['token'];
      _userId = response['user']?['id']?.toString();

      // Set token expiry (for example, 7 days from now)
      _expiryDate = DateTime.now().add(const Duration(days: 7));

      // Save user data for auto-login
      await _saveUserData(
        token: _token!,
        userId: _userId!,
        userType: _userType!,
        expiryDate: _expiryDate!,
      );

      // Set auto logout timer
      _autoLogout();

      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _userType = null;
      notifyListeners();
      rethrow; // Allow UI to handle the error
    }
  }

  Future<bool> register(
      String name, String email, String password, String userType) async {
    try {
      final response =
          await _apiService.registerUser(name, email, password, userType);
      _isAuthenticated = true;
      _userType = response['user']?['user_type'];
      _token = response['token'];
      _userId = response['user']?['id']?.toString();

      // Set token expiry (for example, 7 days from now)
      _expiryDate = DateTime.now().add(const Duration(days: 7));

      // Save user data for auto-login
      await _saveUserData(
        token: _token!,
        userId: _userId!,
        userType: _userType!,
        expiryDate: _expiryDate!,
      );

      // Set auto logout timer
      _autoLogout();

      notifyListeners();
      return true;
    } catch (e) {
      _isAuthenticated = false;
      _userType = null;
      notifyListeners();
      rethrow; // Allow UI to handle the error
    }
  }

  Future<void> logout() async {
    // Clear stored tokens on server
    await _apiService.logout();

    // Clear local authentication data
    _isAuthenticated = false;
    _userType = null;
    _token = null;
    _userId = null;
    _expiryDate = null;

    // Cancel auto logout timer
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }

    // Clear shared preferences data
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');

    notifyListeners();
  }
}
