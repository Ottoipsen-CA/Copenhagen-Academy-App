class ApiConfig {
  // Base URL for API requests
  static const String baseUrl = 'http://localhost:8000';
  
  // Auth endpoints
  static const String loginEndpoint = '$baseUrl/token';
  static const String userEndpoint = '$baseUrl/users/me';
  
  // Player endpoints
  static const String playerStatsEndpoint = '/players/stats';
  static const String playerProfileEndpoint = '/players/profile';
  
  // Training endpoints
  static const String trainingPlansEndpoint = '/training/plans';
  static const String trainingSessionsEndpoint = '/training/sessions';
  
  // Exercise endpoints
  static const String exercisesEndpoint = '$baseUrl/exercises';
  
  // Achievements endpoints
  static const String achievementsEndpoint = '/achievements';
  
  // Chat endpoints
  static const String chatMessagesEndpoint = '/messages';
  
  // Default headers for API requests
  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
} 