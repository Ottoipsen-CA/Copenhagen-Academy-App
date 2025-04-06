import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/player_stats.dart';
import '../models/league_table_entry.dart';
import '../models/challenge.dart';
import 'challenge_service.dart';
import 'package:flutter/material.dart';

class LeagueTableService {
  static const String _leagueTableKey = 'league_table';
  
  // Get all player rankings
  static Future<List<LeagueTableEntry>> getAllRankings() async {
    final prefs = await SharedPreferences.getInstance();
    final tableJson = prefs.getStringList(_leagueTableKey);
    
    if (tableJson != null) {
      try {
        return tableJson
            .map((json) => LeagueTableEntry.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        print('Error loading league table: $e');
      }
    }
    
    // Return mock data if none exists
    final mockTable = _createMockLeagueTable();
    await saveLeagueTable(mockTable);
    return mockTable;
  }
  
  // Save league table
  static Future<void> saveLeagueTable(List<LeagueTableEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final tableJson = entries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    
    await prefs.setStringList(_leagueTableKey, tableJson);
  }
  
  // Get players filtered by position
  static Future<List<LeagueTableEntry>> getPlayersByPosition(String position) async {
    final allPlayers = await getAllRankings();
    
    if (position == 'All') {
      return allPlayers;
    }
    
    return allPlayers
        .where((entry) => entry.user.position == position)
        .toList();
  }
  
  // Get top challenge performers
  static Future<List<LeagueTableEntry>> getTopChallengePerformers() async {
    final allPlayers = await getAllRankings();
    
    // Sort by challenge points
    allPlayers.sort((a, b) => b.challengePoints.compareTo(a.challengePoints));
    
    return allPlayers;
  }
  
  // Create mock data for development
  static List<LeagueTableEntry> _createMockLeagueTable() {
    // Mock positions
    const positions = ['GK', 'CB', 'RB', 'LB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'];
    
    // Mock club names
    const clubs = ['FC Barcelona Youth', 'Ajax Academy', 'La Masia', 'Cobham', 'Clairefontaine'];
    
    // Create 25 mock players with varied stats
    final players = List.generate(25, (index) {
      // Randomize within logical ranges
      final position = positions[index % positions.length];
      
      // Player names
      final playerNames = [
        'Liam Johnson', 'Noah Williams', 'Oliver Smith', 'Elijah Brown', 'William Jones',
        'James Garcia', 'Benjamin Miller', 'Lucas Davis', 'Henry Rodriguez', 'Alexander Martinez',
        'Mason Anderson', 'Michael Taylor', 'Ethan Thomas', 'Daniel Wilson', 'Jacob Anderson',
        'Logan Martinez', 'Jackson Hernandez', 'Sebastian Lopez', 'Jack White', 'Aiden Harris',
        'Owen Clark', 'Samuel Lewis', 'Matthew Robinson', 'Leo Walker', 'David Hall'
      ];
      
      // Adjust stats based on position (simplified)
      double pace = 50 + (index * 1.5) % 40;
      double shooting = 50 + (index * 2) % 40;
      double passing = 50 + (index * 1.8) % 40;
      double dribbling = 50 + (index * 1.7) % 40;
      double defense = 50 + (index * 1.4) % 40;
      double physical = 50 + (index * 1.6) % 40;
      
      // Adjust based on position type
      if (position == 'GK') {
        defense += 20;
        physical += 10;
        pace -= 10;
        shooting -= 20;
      } else if (position == 'CB' || position == 'RB' || position == 'LB') {
        defense += 15;
        physical += 10;
        shooting -= 10;
      } else if (position == 'CDM' || position == 'CM') {
        passing += 10;
        defense += 5;
      } else if (position == 'CAM' || position == 'LW' || position == 'RW') {
        dribbling += 15;
        passing += 10;
        pace += 5;
      } else if (position == 'ST') {
        shooting += 15;
        physical += 5;
        pace += 5;
      }
      
      // Clamp values
      pace = pace.clamp(50, 99);
      shooting = shooting.clamp(50, 99);
      passing = passing.clamp(50, 99);
      dribbling = dribbling.clamp(50, 99);
      defense = defense.clamp(50, 99);
      physical = physical.clamp(50, 99);
      
      // Calculate overall
      final overall = ((pace + shooting + passing + dribbling + defense + physical) / 6).roundToDouble();
      
      // Create stats
      final stats = PlayerStats(
        
        pace: pace,
        shooting: shooting,
        passing: passing,
        dribbling: dribbling,
        juggles: defense,
        firstTouch: physical,
        overallRating: overall,
      );
      
      // Create user
      final user = User(
        id: 100 + index,
        email: 'player$index@example.com',
        fullName: playerNames[index],
        position: position,
        currentClub: clubs[index % clubs.length],
        isActive: true,
      );
      
      // Create league table entry
      return LeagueTableEntry(
        user: user,
        stats: stats,
        rank: index + 1,
        challengePoints: 100 - (index * 3) % 90,
        matchesPlayed: 10 - (index % 5),
        wins: 5 - (index % 5),
        draws: index % 3,
        losses: (index % 4),
      );
    });
    
    // Sort by total points
    players.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    
    // Update ranks
    for (int i = 0; i < players.length; i++) {
      players[i] = LeagueTableEntry(
        user: players[i].user,
        stats: players[i].stats,
        rank: i + 1,
        challengePoints: players[i].challengePoints,
        matchesPlayed: players[i].matchesPlayed,
        wins: players[i].wins,
        draws: players[i].draws,
        losses: players[i].losses,
      );
    }
    
    return players;
  }
} 