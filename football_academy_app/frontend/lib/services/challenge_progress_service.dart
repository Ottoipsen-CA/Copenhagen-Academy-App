import 'dart:convert';
import '../models/user.dart';
import '../models/challenge.dart';
import '../models/challenge_completion.dart';
import '../models/badge.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ChallengeProgressService {
  final ApiService apiService;

  ChallengeProgressService({required this.apiService});

  // Complete a challenge and record performance
  Future<ChallengeCompletion> completeChallenge({
    required int challengeId,
    required int completionTime,
    required double score,
    required Map<String, dynamic> stats,
  }) async {
    final data = {
      'challenge_id': challengeId,
      'completion_time': completionTime,
      'score': score,
      'stats': stats is String ? stats : jsonEncode(stats),
    };

    final response = await apiService.post(
      ApiConfig.challengeComplete,
      data,
      withAuth: true,
    );

    return ChallengeCompletion.fromJson(response);
  }

  // Get all challenge completions for current user
  Future<List<ChallengeCompletionWithDetails>> getUserCompletions() async {
    final response = await apiService.get(
      ApiConfig.challengeCompletions,
      withAuth: true,
    );

    return (response as List)
        .map((item) => ChallengeCompletionWithDetails.fromJson(item))
        .toList();
  }

  // Get all challenge completions for a specific challenge
  Future<List<ChallengeCompletion>> getChallengeCompletions(int challengeId) async {
    final response = await apiService.get(
      '${ApiConfig.challengeCompletions}/$challengeId',
      withAuth: true,
    );

    return (response as List)
        .map((item) => ChallengeCompletion.fromJson(item))
        .toList();
  }

  // Get all badges for current user
  Future<List<BadgeWithChallenge>> getUserBadges() async {
    final response = await apiService.get(
      ApiConfig.badges,
      withAuth: true,
    );

    return (response as List)
        .map((item) => BadgeWithChallenge.fromJson(item))
        .toList();
  }

  // Get badge statistics (by category)
  Future<Map<String, int>> getBadgeStats() async {
    final response = await apiService.get(
      ApiConfig.badgeStats,
      withAuth: true,
    );

    return Map<String, int>.from(response);
  }

  // Get challenge statistics
  Future<Map<String, dynamic>> getChallengeStatistics() async {
    final response = await apiService.get(
      ApiConfig.challengeStatistics,
      withAuth: true,
    );

    return response as Map<String, dynamic>;
  }
} 