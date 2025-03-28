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
    
    // Special handling for 7 Days Juggle Challenge
    if (challenge.title == '7 Days Juggle Challenge') {
      // Count unique days based on the date part of timestamps
      final uniqueDays = <String>{};
      for (final attempt in attempts) {
        final dateStr = '${attempt.timestamp.year}-${attempt.timestamp.month}-${attempt.timestamp.day}';
        uniqueDays.add(dateStr);
      }
      
      // Current value is the number of unique days
      final newCurrentValue = uniqueDays.length;
      
      // Only complete when all 7 days are recorded
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
      
    } else {
      // Standard handling for other challenges
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
    }
    
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
      Challenge(
        id: _uuid.v4(),
        title: 'One-Touch Passing',
        description: 'Complete 25 one-touch passes with a partner without the ball touching the ground.',
        category: ChallengeCategory.passing,
        level: 4,
        targetValue: 25,
        unit: 'passes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Through Ball Mastery',
        description: 'Successfully execute 12 through balls between defenders to a target player.',
        category: ChallengeCategory.passing,
        level: 5,
        targetValue: 12,
        unit: 'passes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Cross Accuracy',
        description: 'Deliver 15 accurate crosses from the wing into the box target area.',
        category: ChallengeCategory.passing,
        level: 6,
        targetValue: 15,
        unit: 'crosses',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'First-Time Crosses',
        description: 'Complete 10 first-time crosses into the designated target area.',
        category: ChallengeCategory.passing,
        level: 7,
        targetValue: 10,
        unit: 'crosses',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Switching Play',
        description: 'Execute 15 accurate long diagonal passes to switch play from one side to the other.',
        category: ChallengeCategory.passing,
        level: 8,
        targetValue: 15,
        unit: 'switches',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Chipped Pass Precision',
        description: 'Complete 12 chipped passes over an obstacle to a teammate.',
        category: ChallengeCategory.passing,
        level: 9,
        targetValue: 12,
        unit: 'passes',
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
      Challenge(
        id: _uuid.v4(),
        title: 'Volley Challenge',
        description: 'Score 5 volleys from crosses into the box.',
        category: ChallengeCategory.shooting,
        level: 3,
        targetValue: 5,
        unit: 'goals',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'First Touch Finish',
        description: 'Control and finish 7 passes with your first and second touch.',
        category: ChallengeCategory.shooting,
        level: 4,
        targetValue: 7,
        unit: 'goals',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Header Challenge',
        description: 'Score 6 headers from crosses into the target areas of the goal.',
        category: ChallengeCategory.shooting,
        level: 5,
        targetValue: 6,
        unit: 'goals',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Free Kick Accuracy',
        description: 'Score 4 free kicks from 20 meters out with a defensive wall.',
        category: ChallengeCategory.shooting,
        level: 6,
        targetValue: 4,
        unit: 'goals',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Chip Shot Master',
        description: 'Score 5 chip shots over the goalkeeper into the net.',
        category: ChallengeCategory.shooting,
        level: 7,
        targetValue: 5,
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
      Challenge(
        id: _uuid.v4(),
        title: 'Figure 8 Dribbling',
        description: 'Complete 10 figure-8 patterns around two cones in under 30 seconds.',
        category: ChallengeCategory.dribbling,
        level: 2,
        targetValue: 10,
        unit: 'patterns',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Close Control Challenge',
        description: 'Dribble through a course of 8 gates that are 1 meter wide without touching any cones.',
        category: ChallengeCategory.dribbling,
        level: 3,
        targetValue: 1,
        unit: 'completion',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Skill Move Master',
        description: 'Execute 5 different skill moves (step-overs, Cruyff turns, etc.) through a cone course.',
        category: ChallengeCategory.dribbling,
        level: 4,
        targetValue: 5,
        unit: 'skill moves',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Speed Dribbling',
        description: 'Dribble 30 meters with the ball under control in under 6 seconds.',
        category: ChallengeCategory.dribbling,
        level: 5,
        targetValue: 1,
        unit: 'completion',
      ),
      Challenge(
        id: _uuid.v4(),
        title: '1v1 Dribbling',
        description: 'Beat a defender in a 1v1 situation 8 times within a restricted area.',
        category: ChallengeCategory.dribbling,
        level: 6,
        targetValue: 8,
        unit: 'successful dribbles',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Tight Space Control',
        description: 'Maintain possession of the ball for 60 seconds in a 2x2 meter square while being pressured.',
        category: ChallengeCategory.dribbling,
        level: 7,
        targetValue: 60,
        unit: 'seconds',
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
      Challenge(
        id: _uuid.v4(),
        title: 'Shuttle Runs',
        description: 'Complete 20 shuttle runs (20 meters) in under 60 seconds.',
        category: ChallengeCategory.fitness,
        level: 2,
        targetValue: 20,
        unit: 'shuttles',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Plank Challenge',
        description: 'Hold a plank position for 3 minutes without breaking form.',
        category: ChallengeCategory.fitness,
        level: 3,
        targetValue: 180,
        unit: 'seconds',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Box Jumps',
        description: 'Complete 30 box jumps (50cm height) with proper form.',
        category: ChallengeCategory.fitness,
        level: 4,
        targetValue: 30,
        unit: 'jumps',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Agility Ladder',
        description: 'Complete 5 different agility ladder drills in under 2 minutes.',
        category: ChallengeCategory.fitness,
        level: 5,
        targetValue: 5,
        unit: 'drills',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Beep Test',
        description: 'Reach level 12 on the beep test (multi-stage fitness test).',
        category: ChallengeCategory.fitness,
        level: 6,
        targetValue: 12,
        unit: 'levels',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Sprint Intervals',
        description: 'Complete 10 sprint intervals of 100 meters with 30 seconds rest between each.',
        category: ChallengeCategory.fitness,
        level: 7,
        targetValue: 10,
        unit: 'sprints',
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
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Interception Master',
        description: 'Successfully intercept 15 passes in a small-sided game.',
        category: ChallengeCategory.defense,
        level: 2,
        targetValue: 15,
        unit: 'interceptions',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Positioning',
        description: 'Maintain proper defensive positioning for 10 minutes in a small-sided game without being dribbled past.',
        category: ChallengeCategory.defense,
        level: 3,
        targetValue: 10,
        unit: 'minutes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Blocking Shots',
        description: 'Block 8 shots in a defensive drill session.',
        category: ChallengeCategory.defense,
        level: 4,
        targetValue: 8,
        unit: 'blocks',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Headers',
        description: 'Win 12 defensive headers from crosses or long balls.',
        category: ChallengeCategory.defense,
        level: 5,
        targetValue: 12,
        unit: 'headers',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Recovery Runs',
        description: 'Perform 15 successful recovery runs to prevent counterattacks.',
        category: ChallengeCategory.defense,
        level: 6,
        targetValue: 15,
        unit: 'recovery runs',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Defensive Organization',
        description: 'Lead and organize a defensive line for a full 15-minute practice match without conceding.',
        category: ChallengeCategory.defense,
        level: 7,
        targetValue: 15,
        unit: 'minutes',
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
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'High Ball Handling',
        description: 'Successfully catch or punch 10 high balls or crosses into the box.',
        category: ChallengeCategory.goalkeeping,
        level: 2,
        targetValue: 10,
        unit: 'catches',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Diving Saves',
        description: 'Make 8 successful diving saves from shots aimed at the corners.',
        category: ChallengeCategory.goalkeeping,
        level: 3,
        targetValue: 8,
        unit: 'saves',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Distribution Accuracy',
        description: 'Complete 12 accurate distributions (throws or kicks) to teammates in specific zones.',
        category: ChallengeCategory.goalkeeping,
        level: 4,
        targetValue: 12,
        unit: 'distributions',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'One-on-One Situations',
        description: 'Successfully stop 6 attackers in one-on-one situations.',
        category: ChallengeCategory.goalkeeping,
        level: 5,
        targetValue: 6,
        unit: 'saves',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Penalty Saving',
        description: 'Save 4 out of 10 penalty kicks.',
        category: ChallengeCategory.goalkeeping,
        level: 6,
        targetValue: 4,
        unit: 'saves',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Sweeper Keeper',
        description: 'Successfully act as a sweeper keeper in 5 situations outside the penalty area.',
        category: ChallengeCategory.goalkeeping,
        level: 7,
        targetValue: 5,
        unit: 'interceptions',
      ),
      
      // Tactical challenges
      Challenge(
        id: _uuid.v4(),
        title: 'Tactical Analysis',
        description: 'Analyze a match and identify 10 key tactical situations.',
        category: ChallengeCategory.tactical,
        level: 1,
        targetValue: 10,
        unit: 'analyses',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Positional Awareness',
        description: 'Maintain optimal positioning for 15 minutes in a small-sided game, as evaluated by a coach.',
        category: ChallengeCategory.tactical,
        level: 2,
        targetValue: 15,
        unit: 'minutes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Team Shape Maintenance',
        description: 'Lead your team in maintaining proper shape for a full 20-minute practice match.',
        category: ChallengeCategory.tactical,
        level: 3,
        targetValue: 20,
        unit: 'minutes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Transition Play',
        description: 'Successfully execute 8 attacking transitions after regaining possession.',
        category: ChallengeCategory.tactical,
        level: 4,
        targetValue: 8,
        unit: 'transitions',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Set Piece Organization',
        description: 'Organize and execute 5 successful set piece routines (corners or free kicks).',
        category: ChallengeCategory.tactical,
        level: 5,
        targetValue: 5,
        unit: 'set pieces',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Game Management',
        description: 'Successfully manage a practice game scenario (e.g., protecting a lead) for 15 minutes.',
        category: ChallengeCategory.tactical,
        level: 6,
        targetValue: 15,
        unit: 'minutes',
      ),
      Challenge(
        id: _uuid.v4(),
        title: 'Tactical Flexibility',
        description: 'Adapt to 3 different formations during a practice match as instructed by the coach.',
        category: ChallengeCategory.tactical,
        level: 7,
        targetValue: 3,
        unit: 'formations',
      ),
    ];
  }
  
  // Get user's badges (simple mock implementation)
  static Future<List<UserBadge>> getUserBadges() async {
    return [];
  }
} 