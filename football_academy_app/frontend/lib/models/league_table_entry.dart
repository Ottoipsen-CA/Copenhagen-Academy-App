import 'package:flutter/material.dart';
import 'user.dart';
import 'player_stats.dart';
import 'challenge.dart';

class LeagueTableEntry {
  final User user;
  final PlayerStats stats;
  final int rank;
  final int challengePoints;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final double? bestResult;
  final DateTime? submittedAt;
  
  LeagueTableEntry({
    required this.user,
    required this.stats,
    required this.rank,
    this.challengePoints = 0,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.bestResult,
    this.submittedAt,
  });
  
  int get totalPoints => challengePoints + (wins * 3) + draws;
  
  factory LeagueTableEntry.fromJson(Map<String, dynamic> json) {
    // Handle flat structure from API response
    if (json.containsKey('user_id')) {
      // Create a simple User object from the flattened data
      final user = User(
        id: json['user_id'],
        email: '',  // Email might not be available in this context
        fullName: json['full_name'] ?? '',
        position: json['position'],
        currentClub: json['current_club'],
        isActive: true,
      );
      
      // Create default stats 
      final stats = PlayerStats.empty();
      
      // Handle best_result as double
      double? bestResult;
      if (json['best_result'] != null) {
        bestResult = json['best_result'] is int 
            ? json['best_result'].toDouble() 
            : json['best_result'];
      }
      
      return LeagueTableEntry(
        user: user,
        stats: stats,
        rank: json['rank'] ?? 0,
        challengePoints: 0,
        bestResult: bestResult,
        submittedAt: json['submitted_at'] != null ? 
          DateTime.parse(json['submitted_at']) : null,
      );
    } 
    
    // Handle the original nested structure if present
    return LeagueTableEntry(
      user: json['user'] != null ? User.fromJson(json['user']) : User(email: '', fullName: 'Unknown'),
      stats: json['stats'] != null ? PlayerStats.fromJson(json['stats']) : PlayerStats.empty(),
      rank: json['rank'] ?? 0,
      challengePoints: json['challenge_points'] ?? 0,
      matchesPlayed: json['matches_played'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'stats': stats.toJson(),
      'rank': rank,
      'challenge_points': challengePoints,
      'matches_played': matchesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'best_result': bestResult,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
} 