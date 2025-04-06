import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';
import '../models/challenge.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerStatsService {
  static const String _playerStatsKey = 'player_stats';
  
  // Rating increment values
  static const double _perfectScoreIncrement = 0.5;    // When player gets 100% completion
  static const double _goodScoreIncrement = 0.35;      // When player gets 80-99% completion
  static const double _averageScoreIncrement = 0.2;    // When player gets 60-79% completion
  static const double _minimumScoreIncrement = 0.1;    // When player completes but with low score
  
  // Maximum possible ratings
  static const double _maxRating = 99.0;
  static const double _maxStartingRating = 65.0;  // Initial cap for new players
  static const double _maxIntermediateRating = 85.0;  // Cap after completing 10 category challenges
  
  // Get player stats from the API
  static Future<PlayerStats?> getPlayerStats() async {
    try {
      // Get current user ID
      final userId = await AuthService.getCurrentUserId();
      
      // Create API service with required parameters
      final client = http.Client();
      final secureStorage = FlutterSecureStorage();
      final apiService = ApiService(client: client, secureStorage: secureStorage);
      
      // Fetch player stats from the API
      final response = await apiService.get('/api/v2/skill-tests/player-stats/$userId');
      
      if (response is Map<String, dynamic>) {
        return PlayerStats.fromJson(response);
      }
      
      return null;
    } catch (e) {
      print('Error fetching player stats: $e');
      return null;
    }
  }
  
  // Update player stats (for future use)
  static Future<bool> updatePlayerStats(BuildContext context, PlayerStats stats) async {
    try {
      // Get current user ID
      final userId = await AuthService.getCurrentUserId();
      
      // Create API service with required parameters
      final client = http.Client();
      final secureStorage = FlutterSecureStorage();
      final apiService = ApiService(client: client, secureStorage: secureStorage);
      
      // Create request payload
      final payload = stats.toJson();
      
      // Send update request
      await apiService.put('/api/v2/skill-tests/player-stats/$userId', payload);
      
      return true;
    } catch (e) {
      print('Error updating player stats: $e');
      return false;
    }
  }
  
  // Save player stats to local storage
  static Future<void> savePlayerStats(PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerStatsKey, jsonEncode(stats.toJson()));
  }
  
  // Create default stats for a new player
  static Future<PlayerStats> _createDefaultStats() async {
    final currentUserId = await AuthService.getCurrentUserId();
    
    final stats = PlayerStats(
      pace: 80.0,
      shooting: 79.0,
      passing: 76.0,
      dribbling: 81.0,
      juggles: 65.0,
      firstTouch: 72.0,
      overallRating: 83.0,
      lastUpdated: DateTime.now(),
    );
    
    await savePlayerStats(stats);
    return stats;
  }
  
  // Calculate performance score from 0.0-1.0 based on challenge completion
  static double _calculatePerformanceScore(UserChallenge userChallenge, Challenge challenge) {
    // For weekly challenges with multiple attempts
    if (userChallenge.attempts != null && userChallenge.attempts!.isNotEmpty) {
      if (challenge.isWeekly) {
        // For a 7-day challenge, check how many days completed
        final daysCompleted = userChallenge.attempts!.length;
        return daysCompleted / 7.0; // Score based on completion percentage
      }
      
      // For regular challenges, use the best attempt
      final bestAttempt = userChallenge.attempts!
          .map((attempt) => attempt.value)
          .reduce((curr, next) => curr > next ? curr : next);
          
      return bestAttempt / challenge.targetValue.toDouble();
    }
    
    // For simple challenges with a current value
    return userChallenge.currentValue / challenge.targetValue.toDouble();
  }
  
  // Calculate rating increment based on performance score
  static double _calculateRatingIncrement(double performanceScore) {
    if (performanceScore >= 1.0) {
      return _perfectScoreIncrement;
    } else if (performanceScore >= 0.8) {
      return _goodScoreIncrement;
    } else if (performanceScore >= 0.6) {
      return _averageScoreIncrement;
    } else {
      return _minimumScoreIncrement;
    }
  }
  
  // Get max rating cap based on number of completed challenges
  static Future<double> _getMaxRatingCap(ChallengeCategory category) async {
    final completedCount = await _getCompletedChallengeCount(category);
    
    if (completedCount < 5) {
      return _maxStartingRating;
    } else if (completedCount < 20) {
      // Linear progression from starting cap to intermediate cap
      final progress = (completedCount - 5) / 15.0; // Progress from 5-20 challenges
      return _maxStartingRating + progress * (_maxIntermediateRating - _maxStartingRating);
    } else {
      // Linear progression from intermediate cap to max rating
      final progress = math.min(1.0, (completedCount - 20) / 30.0); // Progress from 20-50 challenges
      return _maxIntermediateRating + progress * (_maxRating - _maxIntermediateRating);
    }
  }
  
  // Get count of completed challenges in a category
  static Future<int> _getCompletedChallengeCount(ChallengeCategory category) async {
    // This would ideally come from the challenge service
    // For now, we'll mock a value based on category
    switch (category) {
      case ChallengeCategory.passing:
        return 3;
      case ChallengeCategory.shooting:
        return 2;
      case ChallengeCategory.dribbling:
        return 4;
      case ChallengeCategory.fitness:
        return 5;
      case ChallengeCategory.defense:
        return 1;
      case ChallengeCategory.goalkeeping:
        return 0;
      case ChallengeCategory.tactical:
        return 2;
      case ChallengeCategory.wallTouches:
        return 1;
      default:
        return 0;
    }
  }
  
  // Update player stats based on challenge completion
  static Future<PlayerStats> updateStatsFromChallenge(Challenge challenge, UserChallenge userChallenge) async {
    if (userChallenge.status != ChallengeStatus.completed) {
      throw Exception('Cannot update stats from an incomplete challenge.');
    }
    
    // Get current stats
    final currentStats = await getPlayerStats();
    if (currentStats == null) {
      throw Exception('Player stats not found.');
    }
    
    // Calculate performance score and rating increment
    final performanceScore = _calculatePerformanceScore(userChallenge, challenge);
    final baseRatingIncrement = _calculateRatingIncrement(performanceScore);
    
    // Get rating cap for this category
    final maxRatingCap = await _getMaxRatingCap(challenge.category);
    
    // Create modifiable copies of the current stats values
    double pace = currentStats.pace;
    double shooting = currentStats.shooting;
    double passing = currentStats.passing;
    double dribbling = currentStats.dribbling;
    double juggles = currentStats.juggles;
    double firstTouch = currentStats.firstTouch;
    
    // Apply rating increment to appropriate category based on challenge type
    switch (challenge.category) {
      case ChallengeCategory.passing:
        passing = math.min(passing + baseRatingIncrement, maxRatingCap);
        break;
        
      case ChallengeCategory.shooting:
        shooting = math.min(shooting + baseRatingIncrement, maxRatingCap);
        break;
        
      case ChallengeCategory.dribbling:
        dribbling = math.min(dribbling + baseRatingIncrement, maxRatingCap);
        break;
        
      case ChallengeCategory.fitness:
        pace = math.min(pace + baseRatingIncrement * 0.7, maxRatingCap);
        firstTouch = math.min(firstTouch + baseRatingIncrement * 0.3, maxRatingCap);
        break;
        
      case ChallengeCategory.defense:
        juggles = math.min(juggles + baseRatingIncrement, maxRatingCap);
        break;
        
      case ChallengeCategory.goalkeeping:
        juggles = math.min(juggles + baseRatingIncrement * 0.6, maxRatingCap);
        firstTouch = math.min(firstTouch + baseRatingIncrement * 0.4, maxRatingCap);
        break;
        
      case ChallengeCategory.tactical:
        passing = math.min(passing + baseRatingIncrement * 0.3, maxRatingCap);
        juggles = math.min(juggles + baseRatingIncrement * 0.3, maxRatingCap);
        dribbling = math.min(dribbling + baseRatingIncrement * 0.2, maxRatingCap);
        shooting = math.min(shooting + baseRatingIncrement * 0.2, maxRatingCap);
        break;
        
      case ChallengeCategory.weekly:
        // Weekly challenges provide small improvements to all stats
        final smallIncrement = baseRatingIncrement * 0.15;
        pace = math.min(pace + smallIncrement, maxRatingCap);
        shooting = math.min(shooting + smallIncrement, maxRatingCap);
        passing = math.min(passing + smallIncrement, maxRatingCap);
        dribbling = math.min(dribbling + smallIncrement, maxRatingCap);
        juggles = math.min(juggles + smallIncrement, maxRatingCap);
        firstTouch = math.min(firstTouch + smallIncrement, maxRatingCap);
        break;
        
      case ChallengeCategory.wallTouches:
        // Wall touches challenges improve both dribbling and passing
        dribbling = math.min(dribbling + baseRatingIncrement, maxRatingCap);
        passing = math.min(passing + (baseRatingIncrement * 0.5), maxRatingCap);
        break;
    }
    
    // Calculate the new overall rating
    final newOverallRating = _calculateOverallRating(
      pace, shooting, passing, dribbling, juggles, firstTouch
    );
    
    // Create updated stats object
    final updatedStats = PlayerStats(
      pace: pace,
      shooting: shooting,
      passing: passing,
      dribbling: dribbling,
      juggles: juggles,
      firstTouch: firstTouch,
      overallRating: newOverallRating,
      lastUpdated: DateTime.now(),
      lastTestId: currentStats.lastTestId,
    );
    
    // Save updated stats
    await savePlayerStats(updatedStats);
    
    return updatedStats;
  }
  
  // Calculate overall rating based on individual stats
  static double _calculateOverallRating(
    double pace, 
    double shooting, 
    double passing, 
    double dribbling, 
    double juggles, 
    double firstTouch
  ) {
    // Simple average for now
    return (pace + shooting + passing + dribbling + juggles + firstTouch) / 6.0;
  }
} 