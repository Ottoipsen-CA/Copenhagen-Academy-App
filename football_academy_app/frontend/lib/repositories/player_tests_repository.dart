import 'dart:convert';
import '../models/player_test.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class PlayerTestsRepository {
  final ApiService _apiService;
  
  PlayerTestsRepository(this._apiService);
  
  /// Get all tests for the current player
  Future<List<PlayerTest>> getPlayerTests() async {
    try {
      // Get current user ID
      final userId = await AuthService.getCurrentUserId();
      
      // Fetch tests for current player
      final response = await _apiService.get('/api/v2/skill-tests/player-tests/player/$userId');
      
      if (response is List) {
        return response.map((test) => PlayerTest.fromJson(test)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching player tests: $e');
      throw Exception('Failed to load player tests: $e');
    }
  }
  
  /// Submit new test results for the current player
  Future<PlayerTest> submitTestResults(PlayerTest test) async {
    try {
      // Get current user ID
      final userId = await AuthService.getCurrentUserId();
      
      // Create request payload
      final payload = test.toJson();
      
      // Add player ID to the request
      payload['player_id'] = int.parse(userId);
      
      // Submit test results
      final response = await _apiService.post('/api/v2/skill-tests/player-tests', payload);
      
      // Return the created test with ID and other server-added fields
      return PlayerTest.fromJson(response);
    } catch (e) {
      print('Error submitting test results: $e');
      throw Exception('Failed to submit test results: $e');
    }
  }
  
  /// Delete a specific test by ID
  Future<bool> deletePlayerTest(int testId) async {
    try {
      await _apiService.delete('/api/v2/skill-tests/player-tests/$testId');
      return true;
    } catch (e) {
      print('Error deleting player test: $e');
      throw Exception('Failed to delete test: $e');
    }
  }
  
  /// Get player stats calculated from test results
  Future<Map<String, dynamic>> getPlayerStats() async {
    try {
      // Get current user ID
      final userId = await AuthService.getCurrentUserId();
      
      // Fetch player stats using centralized endpoint
      final response = await _apiService.get('${ApiConfig.playerStats}/$userId');
      
      if (response is Map<String, dynamic>) {
        return response;
      }
      
      return {};
    } catch (e) {
      print('Error fetching player stats: $e');
      throw Exception('Failed to load player stats: $e');
    }
  }
} 