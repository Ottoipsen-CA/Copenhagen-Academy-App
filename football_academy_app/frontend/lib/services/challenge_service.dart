import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/badge.dart';
import '../models/player_stats.dart';
import 'package:uuid/uuid.dart';
import 'player_stats_service.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../repositories/challenge_repository.dart';

class ChallengeService {
  static const String _challengesKey = 'challenges';
  static const String _userChallengesKey = 'user_challenges';
  
  static final Uuid _uuid = Uuid();
  static ApiService? _apiService;
  static ChallengeRepository? _challengeRepository;
  
  // Initialize with API service and repository
  static void initialize(ApiService apiService) {
    _apiService = apiService;
    _challengeRepository = ChallengeRepository(apiService);
  }
  
  // Get all challenges with their status from the API
  static Future<List<Challenge>> getAllChallengesWithStatus() async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Get challenges from repository (which uses the API)
      final challenges = await _challengeRepository!.getAll();
      
      if (challenges.isNotEmpty) {
        // Save locally for offline access
        await saveChallenges(challenges);
        return challenges;
      }
      
      // Fallback to local storage if API returned empty list
      return _getLocalChallenges();
    } catch (e) {
      print('Error fetching challenges from API: $e');
      // Fall back to local storage if API fails
      return _getLocalChallenges();
    }
  }
  
  // Get challenges from local storage
  static Future<List<Challenge>> _getLocalChallenges() async {
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
  
  // Opt in to a challenge
  static Future<bool> optInToChallenge(String challengeId) async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Use repository to opt in
      final success = await _challengeRepository!.optInToChallenge(challengeId);
      
      if (success) {
        // Update local status to in progress
        await _updateLocalUserChallengeStatus(
          challengeId, 
          ChallengeStatus.inProgress,
          null
        );
        
        // Refresh all challenges to get updated statuses
        await getAllChallengesWithStatus();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error opting in to challenge via API: $e');
      // Fallback to local approach
      return _startChallengeFallback(challengeId);
    }
  }
  
  // Local fallback for starting a challenge
  static Future<bool> _startChallengeFallback(String challengeId) async {
    try {
      final userChallenges = await getUserChallenges();
      final index = userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
      
      if (index >= 0) {
        // Update status to in progress
        userChallenges[index] = userChallenges[index].copyWith(
          status: ChallengeStatus.inProgress,
        );
        
        await saveUserChallenges(userChallenges);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error in fallback challenge start: $e');
      return false;
    }
  }
  
  // Complete a challenge using the API
  static Future<bool> completeChallenge(String challengeId) async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Submit a result to complete the challenge
      // Using a high value to ensure completion
      final success = await _challengeRepository!.submitChallengeResult(challengeId, 9999.0);
      
      if (success) {
        // Update local status
        await _updateLocalUserChallengeStatus(
          challengeId, 
          ChallengeStatus.completed,
          DateTime.now()
        );
        
        // Refresh all challenges to get updated statuses
        await getAllChallengesWithStatus();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error completing challenge via API: $e');
      // Fallback to local storage approach
      return _completeChallengeFallback(challengeId);
    }
  }
  
  // Submit a challenge result
  static Future<bool> submitChallengeResult(String challengeId, double value) async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Use repository to submit result
      final success = await _challengeRepository!.submitChallengeResult(challengeId, value);
      
      if (success) {
        // Refresh challenges to get updated statuses
        await getAllChallengesWithStatus();
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting challenge result: $e');
      return false;
    }
  }
  
  // Fallback method for completing challenges when API is unavailable
  static Future<bool> _completeChallengeFallback(String challengeId) async {
    try {
      final userChallenges = await getUserChallenges();
      final challenges = await _getLocalChallenges();
      
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
      
      // Update status
      userChallenges[index] = userChallenges[index].copyWith(
        status: ChallengeStatus.completed,
        completedAt: DateTime.now(),
      );
      
      // Save changes
      await saveUserChallenges(userChallenges);
      
      // Local unlock logic as fallback
      await _unlockNextChallenge(challenge);
      
      return true;
    } catch (e) {
      print('Error in fallback challenge completion: $e');
      return false;
    }
  }
  
  // Clear all challenge data (for testing/debugging)
  static Future<void> clearChallengeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_challengesKey);
    await prefs.remove(_userChallengesKey);
    print('Challenge data cleared');
  }

  // Initialize challenge statuses from the API
  static Future<void> initializeUserChallenges() async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Get challenges from API, which should include their status
      final challenges = await getAllChallengesWithStatus();
      
      if (challenges.isEmpty) {
        throw Exception('No challenges found');
      }
      
      // We don't need to initialize separately since the API already returns
      // challenges with their status
    } catch (e) {
      print('Error initializing challenges: $e');
      // Fallback to local initialization
      await _initializeUserChallengesFallback();
    }
  }
  
  // Fallback initialization method
  static Future<void> _initializeUserChallengesFallback() async {
    final challenges = await _getLocalChallenges();
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
        
        // All level 1 challenges are available
        final status = challenge.level == 1 ? ChallengeStatus.available : ChallengeStatus.locked;
        
        newUserChallenges.add(UserChallenge(
          challengeId: challenge.id,
          status: status,
          startedAt: DateTime.now(),
        ));
      }
    }
    
    // Make weekly challenge available
    final weeklyChallenge = challenges.firstWhere(
      (c) => c.isWeekly,
      orElse: () => null as Challenge,
    );
    
    if (weeklyChallenge != null) {
      newUserChallenges.add(UserChallenge(
        challengeId: weeklyChallenge.id,
        status: ChallengeStatus.available,
        startedAt: DateTime.now(),
      ));
    }
    
    await saveUserChallenges(newUserChallenges);
  }
  
  // Update local user challenge status
  static Future<void> _updateLocalUserChallengeStatus(
    String challengeId, 
    ChallengeStatus status,
    DateTime? completedAt
  ) async {
    print('Updating local challenge status - ID: $challengeId, Status: $status');
    
    final userChallenges = await getUserChallenges();
    final index = userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
    
    if (index >= 0) {
      print('Existing challenge found - updating from ${userChallenges[index].status} to $status');
      userChallenges[index] = userChallenges[index].copyWith(
        status: status,
        completedAt: completedAt,
      );
    } else {
      print('New challenge found - creating with status $status');
      userChallenges.add(UserChallenge(
        challengeId: challengeId,
        status: status,
        startedAt: DateTime.now(),
        completedAt: completedAt,
      ));
    }
    
    await saveUserChallenges(userChallenges);
    
    // Print stats on user challenges for debugging
    int lockedCount = 0, availableCount = 0, inProgressCount = 0, completedCount = 0;
    
    for (final uc in userChallenges) {
      switch (uc.status) {
        case ChallengeStatus.locked: lockedCount++; break;
        case ChallengeStatus.available: availableCount++; break;
        case ChallengeStatus.inProgress: inProgressCount++; break;
        case ChallengeStatus.completed: completedCount++; break;
      }
    }
    
    print('User challenges status counts - Locked: $lockedCount, Available: $availableCount, '
        'In Progress: $inProgressCount, Completed: $completedCount');
  }
  
  // Get user challenges (from local storage)
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
  
  // Save challenges to local storage
  static Future<void> saveChallenges(List<Challenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final challengesJson = challenges
        .map((challenge) => jsonEncode(challenge.toJson()))
        .toList();
    
    await prefs.setStringList(_challengesKey, challengesJson);
  }
  
  // Save user challenges to local storage
  static Future<void> saveUserChallenges(List<UserChallenge> userChallenges) async {
    final prefs = await SharedPreferences.getInstance();
    final userChallengesJson = userChallenges
        .map((userChallenge) => jsonEncode(userChallenge.toJson()))
        .toList();
    
    await prefs.setStringList(_userChallengesKey, userChallengesJson);
  }
  
  // Unlock next challenge (local fallback)
  static Future<void> _unlockNextChallenge(Challenge completedChallenge) async {
    if (completedChallenge.isWeekly) {
      return; // No next weekly challenge to unlock
    }
    
    final challenges = await _getLocalChallenges();
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
  
  // Get challenge by ID
  static Future<Challenge?> getChallengeById(String id) async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      return await _challengeRepository!.getById(id);
    } catch (e) {
      print('Error getting challenge by ID from API: $e');
      
      // Fallback to local storage
      final challenges = await _getLocalChallenges();
      return challenges.firstWhere(
        (c) => c.id == id,
        orElse: () => null as Challenge,
      );
    }
  }
  
  // Get weekly challenge
  static Future<Challenge?> getWeeklyChallenge() async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Instead of using the dedicated weekly endpoint, get all challenges and find the active one
      final challenges = await _challengeRepository!.getAll();
      
      // Return the first challenge or null if empty
      return challenges.isNotEmpty ? challenges.first : null;
    } catch (e) {
      print('Error getting active challenge from API: $e');
      
      // Fallback to local storage
      final challenges = await _getLocalChallenges();
      return challenges.isNotEmpty ? challenges.first : null;
    }
  }
  
  // Get user's badges (for future implementation)
  static Future<List<UserBadge>> getUserBadges() async {
    return [];
  }
  
  // Record an attempt for a challenge
  static Future<UserChallenge?> recordAttempt(
    String challengeId, 
    int attemptValue,
    {bool markCompleted = false}
  ) async {
    if (_challengeRepository == null) {
      throw Exception('ChallengeService not initialized. Call initialize() first.');
    }
    
    try {
      // Submit the result to the API
      final success = await _challengeRepository!.submitChallengeResult(
        challengeId, 
        attemptValue.toDouble()
      );
      
      if (success) {
        // Refresh all challenges
        await getAllChallengesWithStatus();
        
        // Get user challenges to update the UI
        final userChallenges = await getUserChallenges();
        final index = userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
        
        if (index >= 0) {
          return userChallenges[index];
        }
      }
      
      return null;
    } catch (e) {
      print('Error recording attempt via API: $e');
      return _recordAttemptFallback(challengeId, attemptValue, markCompleted);
    }
  }
  
  // Fallback for recording an attempt locally
  static Future<UserChallenge?> _recordAttemptFallback(
    String challengeId, 
    int attemptValue,
    bool markCompleted
  ) async {
    final userChallenges = await getUserChallenges();
    final challenges = await _getLocalChallenges();
    
    final challenge = challenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => throw Exception('Challenge not found'),
    );
    
    final index = userChallenges.indexWhere((uc) => uc.challengeId == challengeId);
    if (index < 0) {
      throw Exception('Challenge not started');
    }
    
    // Update current value
    int newValue = userChallenges[index].currentValue + attemptValue;
    
    // Check if challenge completed
    final completed = markCompleted || newValue >= challenge.targetValue.toInt();
    
    userChallenges[index] = userChallenges[index].copyWith(
      currentValue: newValue,
      status: completed ? ChallengeStatus.completed : ChallengeStatus.inProgress,
      completedAt: completed ? DateTime.now() : null,
    );
    
    await saveUserChallenges(userChallenges);
    
    if (completed) {
      // Unlock next challenge if completed
      await _unlockNextChallenge(challenge);
    }
    
    return userChallenges[index];
  }
  
  // Create mock challenges for development
  static List<Challenge> _createMockChallenges() {
    final now = DateTime.now();
    final weeklyDeadline = DateTime(now.year, now.month, now.day + 7);
    
    // Helper method to calculate XP reward based on level and category
    int calculateXpReward(int level, ChallengeCategory category) {
      int baseXP = 100;
      int levelBonus = level * 25;
      
      // Additional XP for difficult categories
      int categoryBonus = 0;
      if (category == ChallengeCategory.tactical || 
          category == ChallengeCategory.defense ||
          category == ChallengeCategory.goalkeeping) {
        categoryBonus = 50;
      }
      
      // Weekly challenges give more XP
      if (category == ChallengeCategory.weekly) {
        categoryBonus += 100;
      }
      
      return baseXP + levelBonus + categoryBonus;
    }
    
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
        xpReward: calculateXpReward(1, ChallengeCategory.weekly),
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
        xpReward: calculateXpReward(1, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Medium Range Passing',
        description: 'Complete 15 accurate passes to a target 15 meters away.',
        category: ChallengeCategory.passing,
        level: 2,
        targetValue: 15,
        unit: 'passes',
        xpReward: calculateXpReward(2, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Long Ball Precision',
        description: 'Hit a 2x2 meter target from 30 meters away 10 times.',
        category: ChallengeCategory.passing,
        level: 3,
        targetValue: 10,
        unit: 'accurate passes',
        xpReward: calculateXpReward(3, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'One-Touch Passing',
        description: 'Complete 25 one-touch passes with a partner without the ball touching the ground.',
        category: ChallengeCategory.passing,
        level: 4,
        targetValue: 25,
        unit: 'passes',
        xpReward: calculateXpReward(4, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Through Ball Mastery',
        description: 'Successfully execute 12 through balls between defenders to a target player.',
        category: ChallengeCategory.passing,
        level: 5,
        targetValue: 12,
        unit: 'passes',
        xpReward: calculateXpReward(5, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Cross Accuracy',
        description: 'Deliver 15 accurate crosses from the wing into the box target area.',
        category: ChallengeCategory.passing,
        level: 6,
        targetValue: 15,
        unit: 'crosses',
        xpReward: calculateXpReward(6, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'First-Time Crosses',
        description: 'Complete 10 first-time crosses into the designated target area.',
        category: ChallengeCategory.passing,
        level: 7,
        targetValue: 10,
        unit: 'crosses',
        xpReward: calculateXpReward(7, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Switching Play',
        description: 'Execute 15 accurate long diagonal passes to switch play from one side to the other.',
        category: ChallengeCategory.passing,
        level: 8,
        targetValue: 15,
        unit: 'switches',
        xpReward: calculateXpReward(8, ChallengeCategory.passing),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Chipped Pass Precision',
        description: 'Complete 12 chipped passes over an obstacle to a teammate.',
        category: ChallengeCategory.passing,
        level: 9,
        targetValue: 12,
        unit: 'passes',
        xpReward: calculateXpReward(9, ChallengeCategory.passing),
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
        xpReward: calculateXpReward(1, ChallengeCategory.shooting),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Edge of Box Finishes',
        description: 'Score 6 goals from the edge of the box out of 10 attempts.',
        category: ChallengeCategory.shooting,
        level: 2,
        targetValue: 6,
        unit: 'goals',
        xpReward: calculateXpReward(2, ChallengeCategory.shooting),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Volley Challenge',
        description: 'Score 5 volleys from crosses into the box.',
        category: ChallengeCategory.shooting,
        level: 3,
        targetValue: 5,
        unit: 'goals',
        xpReward: calculateXpReward(3, ChallengeCategory.shooting),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'First Touch Finish',
        description: 'Control and finish 7 passes with your first and second touch.',
        category: ChallengeCategory.shooting,
        level: 4,
        targetValue: 7,
        unit: 'goals',
        xpReward: calculateXpReward(4, ChallengeCategory.shooting),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Header Challenge',
        description: 'Score 6 headers from crosses into the target areas of the goal.',
        category: ChallengeCategory.shooting,
        level: 5,
        targetValue: 6,
        unit: 'goals',
        xpReward: calculateXpReward(5, ChallengeCategory.shooting),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Free Kick Accuracy',
        description: 'Score 4 free kicks from 20 meters out with a defensive wall.',
        category: ChallengeCategory.shooting,
        level: 6,
        targetValue: 4,
        unit: 'goals',
        xpReward: calculateXpReward(6, ChallengeCategory.shooting),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Chip Shot Master',
        description: 'Score 5 chip shots over the goalkeeper into the net.',
        category: ChallengeCategory.shooting,
        level: 7,
        targetValue: 5,
        unit: 'goals',
        xpReward: calculateXpReward(7, ChallengeCategory.shooting),
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
        xpReward: calculateXpReward(1, ChallengeCategory.dribbling),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Figure 8 Dribbling',
        description: 'Complete 10 figure-8 patterns around two cones in under 30 seconds.',
        category: ChallengeCategory.dribbling,
        level: 2,
        targetValue: 10,
        unit: 'patterns',
        xpReward: calculateXpReward(2, ChallengeCategory.dribbling),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Close Control Challenge',
        description: 'Dribble through a course of 8 gates that are 1 meter wide without touching any cones.',
        category: ChallengeCategory.dribbling,
        level: 3,
        targetValue: 1,
        unit: 'completion',
        xpReward: calculateXpReward(3, ChallengeCategory.dribbling),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Skill Move Master',
        description: 'Execute 5 different skill moves (step-overs, Cruyff turns, etc.) through a cone course.',
        category: ChallengeCategory.dribbling,
        level: 4,
        targetValue: 5,
        unit: 'skill moves',
        xpReward: calculateXpReward(4, ChallengeCategory.dribbling),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Speed Dribbling',
        description: 'Dribble 30 meters with the ball under control in under 6 seconds.',
        category: ChallengeCategory.dribbling,
        level: 5,
        targetValue: 1,
        unit: 'completion',
        xpReward: calculateXpReward(5, ChallengeCategory.dribbling),
      ),
      Challenge(
        id: _uuid.v4(),
        title: '1v1 Dribbling',
        description: 'Beat a defender in a 1v1 situation 8 times within a restricted area.',
        category: ChallengeCategory.dribbling,
        level: 6,
        targetValue: 8,
        unit: 'successful dribbles',
        xpReward: calculateXpReward(6, ChallengeCategory.dribbling),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Tight Space Control',
        description: 'Maintain possession of the ball for 60 seconds in a 2x2 meter square while being pressured.',
        category: ChallengeCategory.dribbling,
        level: 7,
        targetValue: 60,
        unit: 'seconds',
        xpReward: calculateXpReward(7, ChallengeCategory.dribbling),
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
        xpReward: calculateXpReward(1, ChallengeCategory.fitness),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Shuttle Runs',
        description: 'Complete 20 shuttle runs (20 meters) in under 60 seconds.',
        category: ChallengeCategory.fitness,
        level: 2,
        targetValue: 20,
        unit: 'shuttles',
        xpReward: calculateXpReward(2, ChallengeCategory.fitness),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Plank Challenge',
        description: 'Hold a plank position for 3 minutes without breaking form.',
        category: ChallengeCategory.fitness,
        level: 3,
        targetValue: 180,
        unit: 'seconds',
        xpReward: calculateXpReward(3, ChallengeCategory.fitness),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Box Jumps',
        description: 'Complete 30 box jumps (50cm height) with proper form.',
        category: ChallengeCategory.fitness,
        level: 4,
        targetValue: 30,
        unit: 'jumps',
        xpReward: calculateXpReward(4, ChallengeCategory.fitness),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Agility Ladder',
        description: 'Complete 5 different agility ladder drills in under 2 minutes.',
        category: ChallengeCategory.fitness,
        level: 5,
        targetValue: 5,
        unit: 'drills',
        xpReward: calculateXpReward(5, ChallengeCategory.fitness),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Beep Test',
        description: 'Reach level 12 on the beep test (multi-stage fitness test).',
        category: ChallengeCategory.fitness,
        level: 6,
        targetValue: 12,
        unit: 'levels',
        xpReward: calculateXpReward(6, ChallengeCategory.fitness),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Sprint Intervals',
        description: 'Complete 10 sprint intervals of 100 meters with 30 seconds rest between each.',
        category: ChallengeCategory.fitness,
        level: 7,
        targetValue: 10,
        unit: 'sprints',
        xpReward: calculateXpReward(7, ChallengeCategory.fitness),
      ),
      
      // Defense challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Tackle Precision',
        description: 'Complete 10 clean standing tackles in 1v1 situations.',
        category: ChallengeCategory.defense,
        level: 1,
        targetValue: 10,
        unit: 'tackles',
        xpReward: calculateXpReward(1, ChallengeCategory.defense),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Interception Master',
        description: 'Successfully intercept 15 passes in a small-sided game.',
        category: ChallengeCategory.defense,
        level: 2,
        targetValue: 15,
        unit: 'interceptions',
        xpReward: calculateXpReward(2, ChallengeCategory.defense),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Positioning',
        description: 'Maintain proper defensive positioning for 10 minutes in a small-sided game without being dribbled past.',
        category: ChallengeCategory.defense,
        level: 3,
        targetValue: 10,
        unit: 'minutes',
        xpReward: calculateXpReward(3, ChallengeCategory.defense),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Blocking Shots',
        description: 'Block 8 shots in a defensive drill session.',
        category: ChallengeCategory.defense,
        level: 4,
        targetValue: 8,
        unit: 'blocks',
        xpReward: calculateXpReward(4, ChallengeCategory.defense),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Headers',
        description: 'Win 12 defensive headers from crosses or long balls.',
        category: ChallengeCategory.defense,
        level: 5,
        targetValue: 12,
        unit: 'headers',
        xpReward: calculateXpReward(5, ChallengeCategory.defense),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Recovery Runs',
        description: 'Perform 15 successful recovery runs to prevent counterattacks.',
        category: ChallengeCategory.defense,
        level: 6,
        targetValue: 15,
        unit: 'recovery runs',
        xpReward: calculateXpReward(6, ChallengeCategory.defense),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Organization',
        description: 'Lead and organize a defensive line for a full 15-minute practice match without conceding.',
        category: ChallengeCategory.defense,
        level: 7,
        targetValue: 15,
        unit: 'minutes',
        xpReward: calculateXpReward(7, ChallengeCategory.defense),
      ),
      
      // Goalkeeping challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Basic Saves',
        description: 'Make 15 successful saves from shots within the penalty area.',
        category: ChallengeCategory.goalkeeping,
        level: 1,
        targetValue: 15,
        unit: 'saves',
        xpReward: calculateXpReward(1, ChallengeCategory.goalkeeping),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'High Ball Handling',
        description: 'Successfully catch or punch 10 high balls or crosses into the box.',
        category: ChallengeCategory.goalkeeping,
        level: 2,
        targetValue: 10,
        unit: 'catches',
        xpReward: calculateXpReward(2, ChallengeCategory.goalkeeping),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Reflex Saves',
        description: 'Make 8 reflex saves from close-range shots.',
        category: ChallengeCategory.goalkeeping,
        level: 3,
        targetValue: 8,
        unit: 'saves',
        xpReward: calculateXpReward(3, ChallengeCategory.goalkeeping),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Distribution Accuracy',
        description: 'Complete 12 accurate distributions to teammates beyond the halfway line.',
        category: ChallengeCategory.goalkeeping,
        level: 4,
        targetValue: 12,
        unit: 'distributions',
        xpReward: calculateXpReward(4, ChallengeCategory.goalkeeping),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'One-on-One Situations',
        description: 'Successfully save 6 one-on-one situations against attackers.',
        category: ChallengeCategory.goalkeeping,
        level: 5,
        targetValue: 6,
        unit: 'saves',
        xpReward: calculateXpReward(5, ChallengeCategory.goalkeeping),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Penalty Save Master',
        description: 'Save 4 out of 10 penalty kicks.',
        category: ChallengeCategory.goalkeeping,
        level: 6,
        targetValue: 4,
        unit: 'saves',
        xpReward: calculateXpReward(6, ChallengeCategory.goalkeeping),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Sweeper Keeper',
        description: 'Successfully intercept 5 through balls outside the penalty area.',
        category: ChallengeCategory.goalkeeping,
        level: 7,
        targetValue: 5,
        unit: 'interceptions',
        xpReward: calculateXpReward(7, ChallengeCategory.goalkeeping),
      ),
      
      // Tactical challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Match Analysis',
        description: 'Analyze 10 different game situations and identify the correct tactical response.',
        category: ChallengeCategory.tactical,
        level: 1,
        targetValue: 10,
        unit: 'analyses',
        xpReward: calculateXpReward(1, ChallengeCategory.tactical),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Positional Awareness',
        description: 'Maintain optimal positioning in relation to teammates and opponents for 15 minutes.',
        category: ChallengeCategory.tactical,
        level: 2,
        targetValue: 15,
        unit: 'minutes',
        xpReward: calculateXpReward(2, ChallengeCategory.tactical),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Shape',
        description: 'Maintain proper defensive shape with teammates for 20 minutes in a small-sided game.',
        category: ChallengeCategory.tactical,
        level: 3,
        targetValue: 20,
        unit: 'minutes',
        xpReward: calculateXpReward(3, ChallengeCategory.tactical),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Counterattack Transitions',
        description: 'Successfully execute 8 counterattack transitions from defense to attack.',
        category: ChallengeCategory.tactical,
        level: 4,
        targetValue: 8,
        unit: 'transitions',
        xpReward: calculateXpReward(4, ChallengeCategory.tactical),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Set Piece Organization',
        description: 'Successfully organize and execute 5 set pieces (corners, free kicks) resulting in goal-scoring opportunities.',
        category: ChallengeCategory.tactical,
        level: 5,
        targetValue: 5,
        unit: 'set pieces',
        xpReward: calculateXpReward(5, ChallengeCategory.tactical),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Game Management',
        description: 'Demonstrate effective game management skills for 15 minutes while ahead in a match.',
        category: ChallengeCategory.tactical,
        level: 6,
        targetValue: 15,
        unit: 'minutes',
        xpReward: calculateXpReward(6, ChallengeCategory.tactical),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Formation Adaptability',
        description: 'Successfully adapt to 3 different formations during a training session.',
        category: ChallengeCategory.tactical,
        level: 7,
        targetValue: 3,
        unit: 'formations',
        xpReward: calculateXpReward(7, ChallengeCategory.tactical),
      ),
      
      // Wall Touches challenges
      Challenge(
        id: _uuid.v4(),
        title: '30-Day Wall Touches Challenge',
        description: 'Touch the ball against a wall 100 times daily for 30 days to improve ball control!',
        category: ChallengeCategory.wallTouches,
        level: 1,
        targetValue: 30,
        unit: 'days',
        xpReward: calculateXpReward(1, ChallengeCategory.wallTouches),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Wall Touches Speed Challenge',
        description: 'Complete 50 wall touches in under 60 seconds.',
        category: ChallengeCategory.wallTouches,
        level: 2,
        targetValue: 50,
        unit: 'touches',
        xpReward: calculateXpReward(2, ChallengeCategory.wallTouches),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Two-Touch Wall Challenge',
        description: 'Complete 40 two-touch wall passes without dropping the ball.',
        category: ChallengeCategory.wallTouches,
        level: 3,
        targetValue: 40,
        unit: 'passes',
        xpReward: calculateXpReward(3, ChallengeCategory.wallTouches),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Weak Foot Wall Challenge',
        description: 'Complete 30 wall passes using only your weak foot.',
        category: ChallengeCategory.wallTouches,
        level: 4,
        targetValue: 30,
        unit: 'passes',
        xpReward: calculateXpReward(4, ChallengeCategory.wallTouches),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Alternating Feet Wall Touches',
        description: 'Complete 60 alternating foot wall passes without making a mistake.',
        category: ChallengeCategory.wallTouches,
        level: 5,
        targetValue: 60,
        unit: 'passes',
        xpReward: calculateXpReward(5, ChallengeCategory.wallTouches),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Wall Touches Endurance Test',
        description: 'Complete 200 wall touches without stopping or dropping the ball.',
        category: ChallengeCategory.wallTouches,
        level: 6,
        targetValue: 200,
        unit: 'touches',
        xpReward: calculateXpReward(6, ChallengeCategory.wallTouches),
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Wall Touches Skill Variation',
        description: 'Perform 5 different types of wall touches drills (e.g., inside foot, outside foot, thigh control, chest control) for 20 touches each.',
        category: ChallengeCategory.wallTouches,
        level: 7,
        targetValue: 5,
        unit: 'variations',
        xpReward: calculateXpReward(7, ChallengeCategory.wallTouches),
      ),
    ];
  }
} 