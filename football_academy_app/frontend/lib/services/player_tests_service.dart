import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/player_test.dart';
import '../repositories/player_tests_repository.dart';
import 'api_service.dart';

class PlayerTestsService {
  static PlayerTestsRepository? _repository;
  
  // Initialize the service with dependencies
  static void initialize(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    _repository = PlayerTestsRepository(apiService);
  }
  
  // Get the repository, initializing if necessary
  static PlayerTestsRepository _getRepository(BuildContext context) {
    if (_repository == null) {
      initialize(context);
    }
    return _repository!;
  }
  
  // Get all tests for the current player
  static Future<List<PlayerTest>> getPlayerTests(BuildContext context) async {
    final repository = _getRepository(context);
    return await repository.getPlayerTests();
  }
  
  // Submit new test results
  static Future<PlayerTest> submitTestResults(BuildContext context, PlayerTest test) async {
    final repository = _getRepository(context);
    return await repository.submitTestResults(test);
  }
  
  // Delete a test
  static Future<bool> deletePlayerTest(BuildContext context, int testId) async {
    final repository = _getRepository(context);
    return await repository.deletePlayerTest(testId);
  }
  
  // Get player stats to be used in radar chart
  static Future<Map<String, dynamic>> getPlayerStats(BuildContext context) async {
    final repository = _getRepository(context);
    return await repository.getPlayerStats();
  }
} 