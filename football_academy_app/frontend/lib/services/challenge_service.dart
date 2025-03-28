import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/badge.dart';
import 'package:uuid/uuid.dart';

class ChallengeService {
  static const String _challengesKey = 'challenges';
  static const String _userChallengesKey = 'user_challenges';
  
  static final Uuid _uuid = Uuid();
  
  // Get all challenges
  static Future<List<Challenge>> getAllChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final challengesJson = prefs.getStringList(_challengesKey);
    
    if (challengesJson != null) {
      try {
        return challengesJson
            .map((json) => Challenge.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        print('Error loading challenges: $e');
      }
    }
    
    // Return mock challenges if none exist
    final mockChallenges = _createMockChallenges();
    await saveChallenges(mockChallenges);
    return mockChallenges;
  }
  
  // Get user challenges
  static Future<List<UserChallenge>> getUserChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final userChallengesJson = prefs.getStringList(_userChallengesKey);
    
    if (userChallengesJson != null) {
      try {
        return userChallengesJson
            .map((json) => UserChallenge.fromJson(jsonDecode(json)))
            .toList();
      } catch (e) {
        print('Error loading user challenges: $e');
      }
    }
    
    // Return empty list if none exist
    return [];
  }
  
  // Save challenges
  static Future<void> saveChallenges(List<Challenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final challengesJson = challenges
        .map((challenge) => jsonEncode(challenge.toJson()))
        .toList();
    
    await prefs.setStringList(_challengesKey, challengesJson);
  }
  
  // Save user challenges
  static Future<void> saveUserChallenges(List<UserChallenge> userChallenges) async {
    final prefs = await SharedPreferences.getInstance();
    final userChallengesJson = userChallenges
        .map((userChallenge) => jsonEncode(userChallenge.toJson()))
        .toList();
    
    await prefs.setStringList(_userChallengesKey, userChallengesJson);
  }
  
  // Get challenges by category
  static Future<List<Challenge>> getChallengesByCategory(ChallengeCategory category) async {
    final challenges = await getAllChallenges();
    return challenges.where((challenge) => challenge.category == category).toList();
  }
  
  // Get weekly challenge
  static Future<Challenge?> getWeeklyChallenge() async {
    final challenges = await getAllChallenges();
    final weeklyChallenges = challenges.where((challenge) => challenge.isWeekly).toList();
    
    if (weeklyChallenges.isEmpty) {
      return null;
    }
    
    // Return the most recent weekly challenge
    return weeklyChallenges.reduce((a, b) => 
        a.deadline == null ? b : 
        b.deadline == null ? a : 
        a.deadline!.isAfter(b.deadline!) ? a : b);
  }
  
  // Get user challenge status
  static Future<UserChallenge?> getUserChallengeStatus(String challengeId) async {
    final userChallenges = await getUserChallenges();
    try {
      return userChallenges.firstWhere(
        (uc) => uc.challengeId == challengeId,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Start a challenge
  static Future<UserChallenge> startChallenge(String challengeId) async {
    final userChallenges = await getUserChallenges();
    
    // Check if user already has this challenge
    final existingIndex = userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
    
    if (existingIndex >= 0) {
      final existing = userChallenges[existingIndex];
      if (existing.status != ChallengeStatus.locked) {
        return existing; // Challenge already started
      }
    }
    
    // Create new user challenge
    final newUserChallenge = UserChallenge(
      challengeId: challengeId,
      status: ChallengeStatus.inProgress,
      currentValue: 0,
      startedAt: DateTime.now(),
      attempts: [],
    );
    
    if (existingIndex >= 0) {
      userChallenges[existingIndex] = newUserChallenge;
    } else {
      userChallenges.add(newUserChallenge);
    }
    
    await saveUserChallenges(userChallenges);
    return newUserChallenge;
  }
  
  // Record an attempt
  static Future<UserChallenge> recordAttempt(
    String challengeId, 
    int value, 
    {String? notes}
  ) async {
    final userChallenges = await getUserChallenges();
    final challenges = await getAllChallenges();
    
    // Find the challenge
    final challenge = challenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => throw Exception('Challenge not found'),
    );
    
    // Find user challenge
    final index = userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
    if (index < 0) {
      throw Exception('Challenge not started');
    }
    
    UserChallenge userChallenge = userChallenges[index];
    
    // Create attempt
    final attempt = ChallengeAttempt(
      timestamp: DateTime.now(),
      value: value,
      notes: notes,
    );
    
    // Update user challenge
    final attempts = List<ChallengeAttempt>.from(userChallenge.attempts ?? [])
      ..add(attempt);
    
    // Calculate new current value (use highest attempt)
    final newCurrentValue = attempts
        .map((a) => a.value)
        .reduce((max, value) => value > max ? value : max);
    
    // Check if challenge is completed
    ChallengeStatus newStatus = userChallenge.status;
    DateTime? completedAt = userChallenge.completedAt;
    
    if (newCurrentValue >= challenge.targetValue && userChallenge.status != ChallengeStatus.completed) {
      newStatus = ChallengeStatus.completed;
      completedAt = DateTime.now();
      
      // Unlock next challenge in the same category
      await _unlockNextChallenge(challenge);
    }
    
    // Update user challenge
    userChallenge = userChallenge.copyWith(
      currentValue: newCurrentValue,
      status: newStatus,
      completedAt: completedAt,
      attempts: attempts,
    );
    
    userChallenges[index] = userChallenge;
    await saveUserChallenges(userChallenges);
    
    return userChallenge;
  }
  
  // Unlock next challenge in same category
  static Future<void> _unlockNextChallenge(Challenge completedChallenge) async {
    if (completedChallenge.isWeekly) {
      return; // No next weekly challenge to unlock
    }
    
    final challenges = await getAllChallenges();
    final userChallenges = await getUserChallenges();
    
    // Find challenges in the same category
    final categoryChallenges = challenges
        .where((c) => c.category == completedChallenge.category)
        .toList();
    
    // Sort by level
    categoryChallenges.sort((a, b) => a.level.compareTo(b.level));
    
    // Find the next level challenge
    final nextLevelChallenges = categoryChallenges
        .where((c) => c.level == completedChallenge.level + 1)
        .toList();
    
    if (nextLevelChallenges.isEmpty) {
      return; // No next level challenges
    }
    
    // Unlock all challenges at the next level
    for (final nextChallenge in nextLevelChallenges) {
      // Check if user already has this challenge
      final existingIndex = userChallenges.indexWhere((uc) => uc.challengeId == nextChallenge.id);
      
      if (existingIndex >= 0) {
        // Update status to available
        userChallenges[existingIndex] = userChallenges[existingIndex].copyWith(
          status: ChallengeStatus.available,
        );
      } else {
        // Create new user challenge with available status
        userChallenges.add(UserChallenge(
          challengeId: nextChallenge.id,
          status: ChallengeStatus.available,
          startedAt: DateTime.now(), // Just to initialize
        ));
      }
    }
    
    await saveUserChallenges(userChallenges);
  }
  
  // Initialize challenge progress
  static Future<void> initializeUserChallenges() async {
    final challenges = await getAllChallenges();
    final userChallenges = await getUserChallenges();
    
    if (userChallenges.isNotEmpty) {
      return; // Already initialized
    }
    
    final newUserChallenges = <UserChallenge>[];
    
    // For each category, make the first level available and lock the rest
    final categories = ChallengeCategory.values.toList();
    
    for (final category in categories) {
      final categoryChallenges = challenges
          .where((c) => c.category == category && !c.isWeekly)
          .toList();
      
      // Sort by level
      categoryChallenges.sort((a, b) => a.level.compareTo(b.level));
      
      // Process each challenge
      for (int i = 0; i < categoryChallenges.length; i++) {
        final challenge = categoryChallenges[i];
        
        // First level is available, rest are locked
        final status = i == 0 ? ChallengeStatus.available : ChallengeStatus.locked;
        
        newUserChallenges.add(UserChallenge(
          challengeId: challenge.id,
          status: status,
          startedAt: DateTime.now(), // Just to initialize
        ));
      }
    }
    
    // Make weekly challenge available
    final weeklyChallenge = await getWeeklyChallenge();
    if (weeklyChallenge != null) {
      newUserChallenges.add(UserChallenge(
        challengeId: weeklyChallenge.id,
        status: ChallengeStatus.available,
        startedAt: DateTime.now(), // Just to initialize
      ));
    }
    
    await saveUserChallenges(newUserChallenges);
  }
  
  // Create mock challenges for development
  static List<Challenge> _createMockChallenges() {
    final now = DateTime.now();
    final weeklyDeadline = DateTime(now.year, now.month, now.day + 7);
    
    return [
      // Weekly challenge
      Challenge(
        id: _uuid.v4(),
        title: '7 Days Juggle Challenge',
        description: 'This week\'s challenge is to juggle the ball every day for 7 days. Record each day\'s best juggling streak.',
        category: ChallengeCategory.weekly,
        level: 1,
        targetValue: 7,
        unit: 'days',
        deadline: weeklyDeadline,
        isWeekly: true,
        tips: [
          'Try to improve your record each day',
          'Practice different juggling techniques',
          'Record a video of your best attempt'
        ],
      ),
      
      // Passing challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Short Passing Accuracy',
        description: 'Complete 20 accurate short passes against a wall from 5 meters distance.',
        category: ChallengeCategory.passing,
        level: 1,
        targetValue: 20,
        unit: 'passes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Medium Range Passing',
        description: 'Complete 15 accurate passes to a target 15 meters away.',
        category: ChallengeCategory.passing,
        level: 2,
        targetValue: 15,
        unit: 'passes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Long Ball Precision',
        description: 'Hit a 2x2 meter target from 30 meters away 10 times.',
        category: ChallengeCategory.passing,
        level: 3,
        targetValue: 10,
        unit: 'accurate passes',
      ),
      
      // Shooting challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Penalty Kicks',
        description: 'Score 8 out of 10 penalty kicks.',
        category: ChallengeCategory.shooting,
        level: 1,
        targetValue: 8,
        unit: 'goals',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Edge of Box Finishes',
        description: 'Score 6 goals from the edge of the box out of 10 attempts.',
        category: ChallengeCategory.shooting,
        level: 2,
        targetValue: 6,
        unit: 'goals',
      ),
      
      // Dribbling challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Cone Slalom',
        description: 'Complete a 10-cone slalom in under 20 seconds without mistakes.',
        category: ChallengeCategory.dribbling,
        level: 1,
        targetValue: 1,
        unit: 'completion',
      ),
      
      // Fitness challenges
      Challenge(
        id: _uuid.v4(),
        title: '5km Run',
        description: 'Complete a 5km run in under 25 minutes.',
        category: ChallengeCategory.fitness,
        level: 1,
        targetValue: 25,
        unit: 'minutes',
      ),
    ];
  }
  
  // Get user's badges (simple mock implementation)
  static Future<List<UserBadge>> getUserBadges() async {
    return [];
  }
} 