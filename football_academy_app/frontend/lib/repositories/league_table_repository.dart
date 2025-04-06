import 'package:flutter/foundation.dart';
import '../models/league_table_entry.dart';
import '../models/user.dart';
import '../models/player_stats.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class LeagueTableRepository {
  final ApiService _apiService;
  
  LeagueTableRepository(this._apiService);
  
  /// Get the league table for a specific challenge
  Future<List<LeagueTableEntry>> getLeagueTableForChallenge(String challengeId) async {
    try {
      debugPrint('LeagueTableRepository: Fetching league table for challenge $challengeId');
      final response = await _apiService.get('${ApiConfig.leagueTable}/$challengeId');
      
      debugPrint('LeagueTableRepository: Raw response: $response');
      
      if (response == null) {
        debugPrint('LeagueTableRepository: Null response from API');
        return [];
      }
      
      // Handle the response based on its type
      if (response is List) {
        // Direct list response
        debugPrint('LeagueTableRepository: Received list response with ${response.length} items');
        return response.map((item) => LeagueTableEntry.fromJson(item)).toList();
      } else if (response is Map<String, dynamic>) {
        // Map response - check for entries array
        debugPrint('LeagueTableRepository: Received map response: ${response.keys}');
        
        if (response.containsKey('entries') && response['entries'] is List) {
          final List<dynamic> entries = response['entries'];
          debugPrint('LeagueTableRepository: Found entries list with ${entries.length} items');
          
          try {
            final entriesList = entries.map((item) => 
              LeagueTableEntry.fromJson(item as Map<String, dynamic>)
            ).toList();
            return entriesList;
          } catch (e) {
            debugPrint('LeagueTableRepository: Error parsing entries: $e');
            throw Exception('Failed to parse league table data: $e');
          }
        }
        
        // If we can't find the entries list, log the error
        debugPrint('LeagueTableRepository: Could not find entries list in response');
        throw Exception('Unexpected API response format: entries list not found');
      }
      
      debugPrint('LeagueTableRepository: Unexpected response type: ${response.runtimeType}');
      throw Exception('Unexpected API response format');
    } catch (e) {
      debugPrint('LeagueTableRepository: Error fetching league table: $e');
      throw Exception('Failed to fetch league table: $e');
    }
  }
  
  /// Get the league table for the current active/weekly challenge
  /// This requires us to first get the active challenge ID
  Future<List<LeagueTableEntry>> getLeagueTableForActiveChallenge() async {
    try {
      debugPrint('LeagueTableRepository: Fetching active challenge');
      final challengeResponse = await _apiService.get(ApiConfig.challenges);
      
      if (challengeResponse == null) {
        debugPrint('LeagueTableRepository: Null response when fetching challenges');
        return [];
      }
      
      if (challengeResponse is List && challengeResponse.isNotEmpty) {
        // Assuming the first challenge is the active one
        final activeChallenge = challengeResponse.first;
        
        if (activeChallenge is Map<String, dynamic> && activeChallenge.containsKey('id')) {
          final String challengeId = activeChallenge['id'];
          debugPrint('LeagueTableRepository: Found active challenge with ID: $challengeId');
          
          // Now get the league table for this challenge
          return await getLeagueTableForChallenge(challengeId);
        } else {
          debugPrint('LeagueTableRepository: Challenge missing ID field');
          return [];
        }
      } else if (challengeResponse is Map<String, dynamic>) {
        // Handle case where the API returns a map with a data field containing the list
        if (challengeResponse.containsKey('data') && 
            challengeResponse['data'] is List && 
            (challengeResponse['data'] as List).isNotEmpty) {
          
          final List<dynamic> challenges = challengeResponse['data'];
          final activeChallenge = challenges.first;
          
          if (activeChallenge is Map<String, dynamic> && activeChallenge.containsKey('id')) {
            final String challengeId = activeChallenge['id'];
            debugPrint('LeagueTableRepository: Found active challenge with ID: $challengeId in data array');
            
            // Now get the league table for this challenge
            return await getLeagueTableForChallenge(challengeId);
          }
        }
        
        debugPrint('LeagueTableRepository: No usable challenge data found in response');
        return [];
      }
      
      debugPrint('LeagueTableRepository: No active challenges found');
      return [];
    } catch (e) {
      debugPrint('LeagueTableRepository: Error fetching league table for active challenge: $e');
      throw Exception('Failed to fetch active challenge data: $e');
    }
  }
} 