import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/challenge.dart';
import '../models/badge.dart';
import '../config/api_config.dart';

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();
  
  factory ChallengeService() {
    return _instance;
  }
  
  ChallengeService._internal();
  
  // Base URL for challenge API endpoints
  final String _baseUrl = ApiConfig.baseUrl + '/challenges';
  
  // Get the active weekly challenge
  Future<Challenge?> getActiveWeeklyChallenge() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weekly/active'),
        headers: ApiConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Challenge.fromJson(jsonData);
      } else {
        // Return a mock challenge for development
        return _getMockActiveChallenge();
      }
    } catch (e) {
      print('Error fetching active weekly challenge: $e');
      // Return a mock challenge for development
      return _getMockActiveChallenge();
    }
  }
  
  // Generate a mock active challenge for development
  Challenge _getMockActiveChallenge() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 3));
    final endDate = now.add(const Duration(days: 4));
    
    return Challenge(
      id: 'challenge-juggle-001',
      title: '7 Days Juggle Challenge',
      description: 'How many consecutive juggles can you do? Record your best streak over the 7-day period!',
      startDate: startDate,
      endDate: endDate,
      challengeType: 'juggling',
      metric: 'count',
      imageUrl: 'https://example.com/juggling-challenge.jpg',
      participantCount: 47,
      leaderboard: [
        ChallengeSubmission(
          userId: 'user123',
          userName: 'Alex Johnson',
          userImageUrl: 'https://example.com/alex.jpg',
          value: 156.0,
          submittedAt: now.subtract(const Duration(hours: 12)),
          rank: 1,
        ),
        ChallengeSubmission(
          userId: 'user456',
          userName: 'Maria Silva',
          userImageUrl: 'https://example.com/maria.jpg',
          value: 132.0,
          submittedAt: now.subtract(const Duration(hours: 24)),
          rank: 2,
        ),
        ChallengeSubmission(
          userId: 'user789',
          userName: 'David Lee',
          userImageUrl: 'https://example.com/david.jpg',
          value: 118.0,
          submittedAt: now.subtract(const Duration(hours: 36)),
          rank: 3,
        ),
        ChallengeSubmission(
          userId: 'user101',
          userName: 'Sophie Chen',
          userImageUrl: 'https://example.com/sophie.jpg',
          value: 105.0,
          submittedAt: now.subtract(const Duration(hours: 5)),
          rank: 4,
        ),
        ChallengeSubmission(
          userId: 'user202',
          userName: 'Carlos Rodriguez',
          userImageUrl: 'https://example.com/carlos.jpg',
          value: 92.0,
          submittedAt: now.subtract(const Duration(hours: 18)),
          rank: 5,
        ),
      ],
      userSubmission: ChallengeSubmission(
        userId: 'user123',
        userName: 'Alex Johnson',
        userImageUrl: 'https://example.com/alex.jpg',
        value: 156.0,
        submittedAt: now.subtract(const Duration(hours: 12)),
        rank: 1,
      ),
    );
  }
  
  // Get all past weekly challenges
  Future<List<Challenge>> getPastWeeklyChallenges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/weekly/past'),
        headers: ApiConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => Challenge.fromJson(data)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching past weekly challenges: $e');
      return [];
    }
  }
  
  // Submit a result for a challenge
  Future<bool> submitChallengeResult(
    String challengeId,
    double result,
    {String? proofImageUrl}
  ) async {
    try {
      final Map<String, dynamic> body = {
        'result': result,
        if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/$challengeId/submit'),
        headers: ApiConfig.headers,
        body: json.encode(body),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting challenge result: $e');
      return false;
    }
  }
  
  // Get detailed challenge by ID
  Future<Challenge?> getChallengeById(String challengeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$challengeId'),
        headers: ApiConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Challenge.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching challenge details: $e');
      return null;
    }
  }
  
  // Get leaderboard for a challenge
  Future<List<ChallengeSubmission>> getChallengeLeaderboard(
    String challengeId,
    {int limit = 20}
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$challengeId/leaderboard?limit=$limit'),
        headers: ApiConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((data) => ChallengeSubmission.fromJson(data))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching challenge leaderboard: $e');
      return [];
    }
  }
  
  // Get user's badges
  Future<List<UserBadge>> getUserBadges() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me/badges'),
        headers: ApiConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => UserBadge.fromJson(data)).toList();
      } else {
        // Return mock badges for development
        return _getMockBadges();
      }
    } catch (e) {
      print('Error fetching user badges: $e');
      // Return mock badges for development
      return _getMockBadges();
    }
  }
  
  // Generate mock badges for development
  List<UserBadge> _getMockBadges() {
    final now = DateTime.now();
    
    return [
      UserBadge(
        id: 'badge1',
        name: 'Speed Demon',
        description: 'Complete a sprint drill under 5 seconds',
        category: 'skills',
        rarity: BadgeRarity.rare,
        isEarned: true,
        earnedDate: now.subtract(const Duration(days: 5)),
        badgeIcon: UserBadge.getIconForType('dribbling'),
        badgeColor: UserBadge.getColorForRarity(BadgeRarity.rare),
        imageUrl: 'https://example.com/badge1.png',
        iconName: 'dribbling',
        requirement: const BadgeRequirement(
          type: 'skill_level',
          targetValue: 80,
          currentValue: 80,
        ),
      ),
      UserBadge(
        id: 'badge2',
        name: 'Goal Machine',
        description: 'Score 50 goals in practice sessions',
        category: 'skills',
        rarity: BadgeRarity.epic,
        isEarned: true,
        earnedDate: now.subtract(const Duration(days: 12)),
        badgeIcon: UserBadge.getIconForType('shooting'),
        badgeColor: UserBadge.getColorForRarity(BadgeRarity.epic),
        imageUrl: 'https://example.com/badge2.png',
        iconName: 'shooting',
        requirement: const BadgeRequirement(
          type: 'challenge_completions',
          targetValue: 50,
          currentValue: 50,
        ),
      ),
      UserBadge(
        id: 'badge3',
        name: 'Consistent Player',
        description: 'Log in for 7 consecutive days',
        category: 'consistency',
        rarity: BadgeRarity.uncommon,
        isEarned: true,
        earnedDate: now.subtract(const Duration(days: 3)),
        badgeIcon: UserBadge.getIconForType('streak'),
        badgeColor: UserBadge.getColorForRarity(BadgeRarity.uncommon),
        imageUrl: 'https://example.com/badge3.png',
        iconName: 'streak',
        requirement: const BadgeRequirement(
          type: 'login_streak',
          targetValue: 7,
          currentValue: 7,
        ),
      ),
      UserBadge(
        id: 'badge4',
        name: 'Captain',
        description: 'Lead your team to victory 5 times',
        category: 'leadership',
        rarity: BadgeRarity.legendary,
        isEarned: true,
        earnedDate: now.subtract(const Duration(days: 20)),
        badgeIcon: UserBadge.getIconForType('trophy'),
        badgeColor: UserBadge.getColorForRarity(BadgeRarity.legendary),
        imageUrl: 'https://example.com/badge4.png',
        iconName: 'trophy',
        requirement: const BadgeRequirement(
          type: 'leadership',
          targetValue: 5,
          currentValue: 5,
        ),
      ),
      UserBadge(
        id: 'badge5',
        name: 'Passing Master',
        description: 'Achieve 90% passing accuracy',
        category: 'skills',
        rarity: BadgeRarity.epic,
        isEarned: false,
        badgeIcon: UserBadge.getIconForType('passing'),
        badgeColor: UserBadge.getColorForRarity(BadgeRarity.epic),
        imageUrl: 'https://example.com/badge5.png',
        iconName: 'passing',
        requirement: const BadgeRequirement(
          type: 'skill_level',
          targetValue: 90,
          currentValue: 75,
        ),
      ),
      UserBadge(
        id: 'badge6',
        name: 'Challenge Champion',
        description: 'Win 3 weekly challenges',
        category: 'challenges',
        rarity: BadgeRarity.legendary,
        isEarned: false,
        badgeIcon: UserBadge.getIconForType('trophy'),
        badgeColor: UserBadge.getColorForRarity(BadgeRarity.legendary),
        imageUrl: 'https://example.com/badge6.png',
        iconName: 'trophy',
        requirement: const BadgeRequirement(
          type: 'challenge_wins',
          targetValue: 3,
          currentValue: 1,
        ),
      ),
    ];
  }
  
  // Get challenge winners (for past challenges)
  Future<List<ChallengeWinner>> getChallengeWinners({int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/winners?limit=$limit'),
        headers: ApiConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => ChallengeWinner.fromJson(data)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching challenge winners: $e');
      return [];
    }
  }
}

// Challenge Winner model
class ChallengeWinner {
  final String userId;
  final String username;
  final String profileImageUrl;
  final String challengeId;
  final String challengeTitle;
  final DateTime challengeEndDate;
  final double result;
  
  ChallengeWinner({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeEndDate,
    required this.result,
  });
  
  factory ChallengeWinner.fromJson(Map<String, dynamic> json) {
    return ChallengeWinner(
      userId: json['userId'],
      username: json['username'],
      profileImageUrl: json['profileImageUrl'] ?? '',
      challengeId: json['challengeId'],
      challengeTitle: json['challengeTitle'],
      challengeEndDate: DateTime.parse(json['challengeEndDate']),
      result: json['result'].toDouble(),
    );
  }
} 