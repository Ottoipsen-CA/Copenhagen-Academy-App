import 'package:flutter/foundation.dart';
import '../models/challenge.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'base_repository.dart';

class ChallengeRepository implements BaseRepository<Challenge> {
  final ApiService _apiService;
  
  ChallengeRepository(this._apiService);
  
  // Use only the main challenges endpoint for all operations
  
  @override
  Future<List<Challenge>> getAll() async {
    try {
      final response = await _apiService.get(ApiConfig.challenges);
      
      if (response != null) {
        return (response as List)
            .map((item) => Challenge.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching challenges: $e');
      return [];
    }
  }
  
  @override
  Future<Challenge?> getById(String id) async {
    try {
      final response = await _apiService.get('${ApiConfig.challenges}/$id');
      
      if (response != null) {
        return Challenge.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching challenge by ID: $e');
      return null;
    }
  }
  
  @override
  Future<Challenge> create(Challenge item) async {
    try {
      final response = await _apiService.post(
        ApiConfig.challenges,
        item.toJson(),
      );
      
      return Challenge.fromJson(response);
    } catch (e) {
      debugPrint('Error creating challenge: $e');
      throw Exception('Failed to create challenge');
    }
  }
  
  @override
  Future<Challenge> update(Challenge item) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.challenges}/${item.id}',
        item.toJson(),
      );
      
      return Challenge.fromJson(response);
    } catch (e) {
      debugPrint('Error updating challenge: $e');
      throw Exception('Failed to update challenge');
    }
  }
  
  @override
  Future<bool> delete(String id) async {
    try {
      final response = await _apiService.delete('${ApiConfig.challenges}/$id');
      return response != null;
    } catch (e) {
      debugPrint('Error deleting challenge: $e');
      return false;
    }
  }
  
  // Additional methods specific to challenge functionality
  
  /// Opt-in to a challenge
  Future<bool> optInToChallenge(String challengeId) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.challenges}/opt-in/$challengeId',
        {},
      );
      
      return response != null;
    } catch (e) {
      debugPrint('Error opting in to challenge: $e');
      return false;
    }
  }
  
  /// Submit a result for a challenge
  Future<bool> submitChallengeResult(String challengeId, double value) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.challenges}/submit-result/$challengeId?result_value=$value',
        {},
      );
      
      return response != null;
    } catch (e) {
      debugPrint('Error submitting challenge result: $e');
      return false;
    }
  }
  
  /// Get user's active challenges - uses the main endpoint since we don't have a specific user endpoint
  Future<List<Challenge>> getUserChallenges() async {
    try {
      final response = await _apiService.get(ApiConfig.challenges);
      
      if (response != null) {
        final challenges = (response as List)
            .map((item) => Challenge.fromJson(item))
            .toList();
            
        // Filter for challenges that have user data
        return challenges.where((c) => 
          c.status == ChallengeStatus.inProgress || 
          c.status == ChallengeStatus.completed ||
          c.userSubmission != null
        ).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user challenges: $e');
      return [];
    }
  }
  
  /// Get active challenge - uses the main endpoint
  Future<Challenge?> getWeeklyChallenge() async {
    try {
      final response = await _apiService.get(ApiConfig.challenges);
      
      if (response != null) {
        final challenges = (response as List)
            .map((item) => Challenge.fromJson(item))
            .toList();
            
        // Return the first challenge (assumed to be the active one)
        return challenges.isNotEmpty ? challenges.first : null;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching active challenge: $e');
      return null;
    }
  }
} 