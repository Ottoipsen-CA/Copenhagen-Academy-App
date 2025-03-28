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
  
  LeagueTableEntry({
    required this.user,
    required this.stats,
    required this.rank,
    required this.challengePoints,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
  });
  
  int get totalPoints => challengePoints + (wins * 3) + draws;
  
  factory LeagueTableEntry.fromJson(Map<String, dynamic> json) {
    return LeagueTableEntry(
      user: User.fromJson(json['user']),
      stats: PlayerStats.fromJson(json['stats']),
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
    };
  }
} 