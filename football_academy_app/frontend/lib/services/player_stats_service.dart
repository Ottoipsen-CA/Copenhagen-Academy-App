import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_stats.dart';
import '../models/challenge.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  
  // Load player stats from API or local storage
  static Future<PlayerStats?> getPlayerStats() async {
    // Try to get stats from the backend API
    try {
      // Create API client
      final client = http.Client();
      final secureStorage = FlutterSecureStorage();
      final apiService = ApiService(client: client, secureStorage: secureStorage);
      
      // Get user info to get current user ID
      final userJson = await apiService.get('/users/me');
      final userId = userJson['id'];
      
      // Force clear the cache to ensure we get the most up-to-date stats
      print('Fetching fresh player stats for user $userId from API');
      
      // Get player stats from API
      final statsJson = await apiService.get('/player-stats/$userId?ts=${DateTime.now().millisecondsSinceEpoch}');
      
      if (statsJson != null) {
        print('Successfully fetched player stats: $statsJson');
        
        // Convert backend stats format to our model
        final stats = PlayerStats(
          id: statsJson['id'],
          playerId: statsJson['player_id'].toString(),
          pace: statsJson['pace'].toDouble(),
          shooting: statsJson['shooting'].toDouble(),
          passing: statsJson['passing'].toDouble(),
          dribbling: statsJson['dribbling'].toDouble(),
          defense: statsJson['defense'].toDouble(),
          physical: statsJson['physical'].toDouble(),
          overallRating: statsJson['overall_rating'].toDouble(),
          lastUpdated: DateTime.parse(statsJson['last_updated']),
        );
        
        // Save to local storage as a backup
        await savePlayerStats(stats);
        
        return stats;
      }
    } catch (e) {
      print('Error fetching player stats from API: $e');
      print('Falling back to local storage');
    }
    
    // If API fetch failed, try local storage
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_playerStatsKey);
    
    if (statsJson != null) {
      try {
        return PlayerStats.fromJson(jsonDecode(statsJson));
      } catch (e) {
        print('Error loading player stats from local storage: $e');
      }
    }
    
    // If no stats exist, create default stats
    return await _createDefaultStats();
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
      playerId: currentUserId,
      pace: 80.0,
      shooting: 79.0,
      passing: 76.0,
      dribbling: 81.0,
      defense: 49.0,
      physical: 70.0,
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
    final stats = await getPlayerStats();
    if (stats == null) {
      throw Exception('Player stats not found.');
    }
    
    // Calculate performance score and rating increment
    final performanceScore = _calculatePerformanceScore(userChallenge, challenge);
    final baseRatingIncrement = _calculateRatingIncrement(performanceScore);
    
    // Get rating cap for this category
    final maxRatingCap = await _getMaxRatingCap(challenge.category);
    
    // Apply rating increment to appropriate category
    // and ensure we don't exceed the category's rating cap
    PlayerStats updatedStats;
    
    switch (challenge.category) {
      case ChallengeCategory.passing:
        final newPassingRating = math.min(stats.passing + baseRatingIncrement, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: stats.shooting,
          passing: newPassingRating,
          dribbling: stats.dribbling,
          defense: stats.defense,
          physical: stats.physical,
          lastUpdated: DateTime.now(),
          // Recalculate overall rating
          overallRating: _calculateOverallRating(
            stats.pace, 
            stats.shooting, 
            newPassingRating,
            stats.dribbling,
            stats.defense,
            stats.physical
          ),
        );
        break;
        
      case ChallengeCategory.shooting:
        final newShootingRating = math.min(stats.shooting + baseRatingIncrement, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: newShootingRating,
          passing: stats.passing,
          dribbling: stats.dribbling,
          defense: stats.defense,
          physical: stats.physical,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            stats.pace, 
            newShootingRating, 
            stats.passing,
            stats.dribbling,
            stats.defense,
            stats.physical
          ),
        );
        break;
        
      case ChallengeCategory.dribbling:
        final newDribblingRating = math.min(stats.dribbling + baseRatingIncrement, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: stats.shooting,
          passing: stats.passing,
          dribbling: newDribblingRating,
          defense: stats.defense,
          physical: stats.physical,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            stats.pace, 
            stats.shooting, 
            stats.passing,
            newDribblingRating,
            stats.defense,
            stats.physical
          ),
        );
        break;
        
      case ChallengeCategory.fitness:
        final newPaceRating = math.min(stats.pace + baseRatingIncrement * 0.7, maxRatingCap);
        final newPhysicalRating = math.min(stats.physical + baseRatingIncrement * 0.3, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: newPaceRating,
          shooting: stats.shooting,
          passing: stats.passing,
          dribbling: stats.dribbling,
          defense: stats.defense,
          physical: newPhysicalRating,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            newPaceRating, 
            stats.shooting, 
            stats.passing,
            stats.dribbling,
            stats.defense,
            newPhysicalRating
          ),
        );
        break;
        
      case ChallengeCategory.defense:
        final newDefenseRating = math.min(stats.defense + baseRatingIncrement, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: stats.shooting,
          passing: stats.passing,
          dribbling: stats.dribbling,
          defense: newDefenseRating,
          physical: stats.physical,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            stats.pace, 
            stats.shooting, 
            stats.passing,
            stats.dribbling,
            newDefenseRating,
            stats.physical
          ),
        );
        break;
        
      case ChallengeCategory.goalkeeping:
        // Goalkeeping challenges primarily improve defense and reactions
        final newDefenseRating = math.min(stats.defense + baseRatingIncrement * 0.6, maxRatingCap);
        final newPhysicalRating = math.min(stats.physical + baseRatingIncrement * 0.4, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: stats.shooting,
          passing: stats.passing,
          dribbling: stats.dribbling,
          defense: newDefenseRating,
          physical: newPhysicalRating,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            stats.pace, 
            stats.shooting, 
            stats.passing,
            stats.dribbling,
            newDefenseRating,
            newPhysicalRating
          ),
        );
        break;
        
      case ChallengeCategory.tactical:
        // Tactical challenges improve multiple attributes slightly
        final newPassingRating = math.min(stats.passing + baseRatingIncrement * 0.3, maxRatingCap);
        final newDefenseRating = math.min(stats.defense + baseRatingIncrement * 0.3, maxRatingCap);
        final newDribblingRating = math.min(stats.dribbling + baseRatingIncrement * 0.2, maxRatingCap);
        final newShootingRating = math.min(stats.shooting + baseRatingIncrement * 0.2, maxRatingCap);
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: newShootingRating,
          passing: newPassingRating,
          dribbling: newDribblingRating,
          defense: newDefenseRating,
          physical: stats.physical,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            stats.pace, 
            newShootingRating, 
            newPassingRating,
            newDribblingRating,
            newDefenseRating,
            stats.physical
          ),
        );
        break;
        
      case ChallengeCategory.weekly:
        // Weekly challenges provide small improvements to all stats
        final smallIncrement = baseRatingIncrement * 0.15;
        final newPaceRating = math.min(stats.pace + smallIncrement, maxRatingCap);
        final newShootingRating = math.min(stats.shooting + smallIncrement, maxRatingCap);
        final newPassingRating = math.min(stats.passing + smallIncrement, maxRatingCap);
        final newDribblingRating = math.min(stats.dribbling + smallIncrement, maxRatingCap);
        final newDefenseRating = math.min(stats.defense + smallIncrement, maxRatingCap);
        final newPhysicalRating = math.min(stats.physical + smallIncrement, maxRatingCap);
        
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: newPaceRating,
          shooting: newShootingRating,
          passing: newPassingRating,
          dribbling: newDribblingRating,
          defense: newDefenseRating,
          physical: newPhysicalRating,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            newPaceRating, 
            newShootingRating, 
            newPassingRating,
            newDribblingRating,
            newDefenseRating,
            newPhysicalRating
          ),
        );
        break;
        
      case ChallengeCategory.wallTouches:
        // Wall touches challenges improve both dribbling and passing
        final newDribblingRating = math.min(stats.dribbling + baseRatingIncrement, maxRatingCap);
        final newPassingRating = math.min(stats.passing + (baseRatingIncrement * 0.5), maxRatingCap);
        
        updatedStats = PlayerStats(
          id: stats.id,
          playerId: stats.playerId,
          pace: stats.pace,
          shooting: stats.shooting,
          passing: newPassingRating,
          dribbling: newDribblingRating,
          defense: stats.defense,
          physical: stats.physical,
          lastUpdated: DateTime.now(),
          overallRating: _calculateOverallRating(
            stats.pace, 
            stats.shooting, 
            newPassingRating,
            newDribblingRating,
            stats.defense,
            stats.physical
          ),
        );
        break;
    }
    
    // Save updated stats
    await savePlayerStats(updatedStats);
    
    return updatedStats;
  }
  
  // Calculate overall rating based on individual stats
  // Different weightings for different positions could be implemented here
  static double _calculateOverallRating(
    double pace, 
    double shooting, 
    double passing, 
    double dribbling, 
    double defense, 
    double physical
  ) {
    // Simple average for now
    return (pace + shooting + passing + dribbling + defense + physical) / 6.0;
  }
} 