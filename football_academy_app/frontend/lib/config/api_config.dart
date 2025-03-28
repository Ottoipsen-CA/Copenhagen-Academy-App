import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Base URL for all API requests
  static const String baseUrl = 'https://api.footballacademy.dev/v1';
  
  // API endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String userProfile = '/users/me';
  static const String challenges = '/challenges';
  static const String badges = '/users/me/badges';
  
  // Get request headers with authorization
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
  
  // Private token storage
  static String? _authToken;
  
  // Initialize the token from shared preferences
  static Future<void> initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }
  
  // Set the auth token (usually after login)
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Clear the auth token (usually after logout)
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Check if user is authenticated
  static bool get isAuthenticated => _authToken != null;
} 