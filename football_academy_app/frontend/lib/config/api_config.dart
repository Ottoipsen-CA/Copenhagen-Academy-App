import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Base URL for all API requests
  static const String baseUrl = 'http://localhost:8080';
  
  // API endpoints - updated to match backend v2 paths
  static const String login = '/api/v2/auth/token';
  static const String register = '/api/v2/auth/register';
  static const String refreshToken = '/api/v2/auth/refresh';
  static const String userProfile = '/api/v2/auth/me';
  
  // Challenge endpoints
  static const String challenges = '/api/v2/challenges';
  static const String challengeOptIn = '/api/v2/challenges/opt-in'; // Append /{challengeId}
  static const String challengeSubmitResult = '/api/v2/challenges/submit-result'; // Append /{challengeId}?result_value=X
  
  // Challenge progress endpoints
  static const String challengeProgress = '/api/v2/challenge-progress';
  static const String challengeComplete = '/api/v2/challenge-progress/complete';
  static const String challengeCompletions = '/api/v2/challenge-progress/completions';
  static const String badgeStats = '/api/v2/challenge-progress/badge-stats';
  static const String challengeStatistics = '/api/v2/challenge-progress/statistics';
  
  // Development Plan endpoints
  static const String developmentPlans = '/api/v2/development-plans/';
  
  // Training Schedule endpoints
  static const String trainingSchedules = '/api/v2/training-schedules/';
  static const String trainingSessions = '/api/v2/training-schedules/sessions'; // No trailing slash to match backend
  
  // Skill tests endpoints
  static const String playerTests = '/api/v2/skill-tests/player-tests';
  static const String playerTestsByPlayer = '/api/v2/skill-tests/player-tests/player'; // Append /{userId}
  
  // Other endpoints
  static const String badges = '/api/v2/users/me/badges';
  static const String playerStats = '/api/v2/skill-tests/player-stats'; // Append /{userId}
  static const String leagueTable = '/api/v2/league-table/challenge'; // Append /{challengeId}
  
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