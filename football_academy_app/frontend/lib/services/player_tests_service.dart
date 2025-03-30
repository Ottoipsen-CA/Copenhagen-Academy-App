import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/player_test.dart';
import 'api_service.dart';
import 'auth_service.dart';

class PlayerTestsService {
  static final ApiService _apiService = ApiService(
    client: http.Client(),
    secureStorage: FlutterSecureStorage(),
  );

  // Submit player test
  static Future<PlayerTest> submitTestResults(PlayerTest test) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      
      // Make sure the test has the correct player ID
      final testData = {
        ...test.toJson(),
        'player_id': int.parse(userId),
      };
      
      print('Submitting test results: $testData');
      
      // Submit to API
      final response = await _apiService.post('/player-tests/', testData);
      
      if (response == null) {
        throw Exception('Failed to submit test results');
      }
      
      print('Test results submitted successfully: $response');
      
      // Parse response and return the created test with ID and ratings
      return PlayerTest.fromJson(response);
    } catch (e) {
      print('Error submitting test results: $e');
      rethrow;
    }
  }

  // Get latest test for player
  static Future<PlayerTest?> getLatestTest() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      final response = await _apiService.get('/player-tests/$userId/latest');
      
      if (response == null) {
        return null;
      }
      
      return PlayerTest.fromJson(response);
    } catch (e) {
      print('Error getting latest test: $e');
      return null;
    }
  }

  // Get all tests for player
  static Future<List<PlayerTest>> getPlayerTests() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      final response = await _apiService.get('/player-tests/$userId');
      
      if (response == null) {
        return [];
      }
      
      return (response as List)
          .map((test) => PlayerTest.fromJson(test))
          .toList();
    } catch (e) {
      print('Error getting player tests: $e');
      return [];
    }
  }
} 