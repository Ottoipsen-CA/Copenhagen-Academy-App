import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/player_stats.dart';
import '../models/league_table_entry.dart';
import '../models/challenge.dart';
import '../repositories/league_table_repository.dart';
import 'api_service.dart';
import 'challenge_service.dart';

class LeagueTableService {
  static const String _leagueTableKey = 'league_table';
  static LeagueTableRepository? _repository;
  static ApiService? _apiService;
  
  // Initialize with API service
  static void initialize(ApiService apiService) {
    _apiService = apiService;
    _repository = LeagueTableRepository(apiService);
  }
  
  // Get league table rankings for the active challenge
  static Future<List<LeagueTableEntry>> getAllRankings() async {
    // Make sure we're initialized
    if (_repository == null) {
      throw Exception('LeagueTableService not initialized. Call initialize() first.');
    }
    
    try {
      // Try to get data from API first
      final leagueTableEntries = await _repository!.getLeagueTableForActiveChallenge();
      
      if (leagueTableEntries.isNotEmpty) {
        // Cache the data locally
        await saveLeagueTable(leagueTableEntries);
        return leagueTableEntries;
      }
      
      // If API returns empty but we have cached data, use that
      final cachedData = await _getLocalLeagueTable();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      
      // If there's really no data, return empty list
      return [];
    } catch (e) {
      debugPrint('Error fetching league table from API: $e');
      
      // Try to get cached data instead
      final cachedData = await _getLocalLeagueTable();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      
      // If no cached data either, rethrow the exception
      throw Exception('Failed to fetch league table: $e');
    }
  }
  
  // Get league table for a specific challenge
  static Future<List<LeagueTableEntry>> getLeagueTableForChallenge(String challengeId) async {
    // Make sure we're initialized
    if (_repository == null) {
      throw Exception('LeagueTableService not initialized. Call initialize() first.');
    }
    
    try {
      // Try to get data from API first
      final leagueTableEntries = await _repository!.getLeagueTableForChallenge(challengeId);
      
      if (leagueTableEntries.isNotEmpty) {
        // Cache the data locally with the challenge ID
        await saveLeagueTable(leagueTableEntries);
        return leagueTableEntries;
      }
      
      // If API returns empty but we have cached data, use that
      final cachedData = await _getLocalLeagueTable();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      
      // If there's really no data, return empty list
      return [];
    } catch (e) {
      debugPrint('Error fetching league table for challenge $challengeId: $e');
      
      // Try to get cached data instead
      final cachedData = await _getLocalLeagueTable();
      if (cachedData.isNotEmpty) {
        return cachedData;
      }
      
      // If no cached data either, rethrow the exception
      throw Exception('Failed to fetch league table for challenge $challengeId: $e');
    }
  }
  
  // Get local league table data
  static Future<List<LeagueTableEntry>> _getLocalLeagueTable() async {
    final prefs = await SharedPreferences.getInstance();
    final tableJson = prefs.getStringList(_leagueTableKey);
    
    if (tableJson != null) {
      try {
        final entries = tableJson
            .map((json) => LeagueTableEntry.fromJson(jsonDecode(json)))
            .toList();
            
        if (entries.isNotEmpty) {
          return entries;
        }
      } catch (e) {
        debugPrint('Error loading league table from cache: $e');
      }
    }
    
    return [];
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
  
  // Clear stored league table data (useful for testing)
  static Future<void> clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leagueTableKey);
  }
} 