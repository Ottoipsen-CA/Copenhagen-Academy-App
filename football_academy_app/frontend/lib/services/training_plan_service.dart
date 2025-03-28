import 'dart:math';
import 'package:flutter/material.dart';
import '../models/training_plan.dart';
import '../models/user.dart';
import '../models/player_stats.dart';
import '../services/auth_service.dart';
import '../services/exercise_service.dart';

class TrainingPlanService {
  final AuthService _authService;
  final ExerciseService _exerciseService;
  
  // Add missing field for mock training plans
  final List<TrainingPlan> _mockTrainingPlans = [];
  
  TrainingPlanService(this._authService, this._exerciseService);
  
  // Initialize mock data constructor
  TrainingPlanService._internal(this._authService) : _exerciseService = null {
    _initMockData();
  }
  
  // Factory constructor to ensure mock data is initialized only once
  static final TrainingPlanService _instance = TrainingPlanService._internal(AuthService(apiService: null, secureStorage: null));
  
  factory TrainingPlanService.withAuthService(AuthService authService) {
    return _instance;
  }
  
  void _initMockData() {
    // Clear existing data to avoid duplicates
    _mockTrainingPlans.clear();
    
    // Add mock training plans
    _mockTrainingPlans.addAll([
      TrainingPlan(
        id: "1",
        title: "Striker Finishing Program",
        focusArea: ["Shooting", "Ball Control"],
        playerLevel: "Intermediate",
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 28)),
        weeks: _generateMockWeeks(4),
        progress: 25,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        userId: "1",
      ),
      TrainingPlan(
        id: "2",
        title: "Midfield Mastery",
        focusArea: ["Passing", "Vision"],
        playerLevel: "Advanced",
        startDate: DateTime.now().subtract(const Duration(days: 14)),
        endDate: DateTime.now().add(const Duration(days: 14)),
        weeks: _generateMockWeeks(4),
        progress: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        userId: "1",
      ),
    ]);
  }
  
  List<TrainingWeek> _generateMockWeeks(int numWeeks) {
    final List<TrainingWeek> weeks = [];
    
    for (int i = 0; i < numWeeks; i++) {
      weeks.add(
        TrainingWeek(
          weekNumber: i + 1,
          title: 'Week ${i + 1}',
          description: 'Week ${i + 1} training sessions',
          difficulty: i < numWeeks / 2 ? 'Intermediate' : 'Advanced',
          sessions: _generateMockSessions(3 + i),
        ),
      );
    }
    
    return weeks;
  }
  
  List<TrainingSession> _generateMockSessions(int numSessions) {
    final List<TrainingSession> sessions = [];
    
    final sessionTypes = [
      "Technical Drills",
      "Physical Training",
      "Tactical Session",
      "Match Simulation",
      "Recovery Session"
    ];
    
    final List<String> intensities = ["Low", "Medium", "High"];
    
    for (int i = 0; i < numSessions; i++) {
      sessions.add(
        TrainingSession(
          id: "s${i + 1}",
          title: sessionTypes[i % sessionTypes.length],
          description: "A ${intensities[i % intensities.length]} intensity session focused on improving skills",
          durationMinutes: 45 + (i * 15),
          intensity: intensities[i % intensities.length],
          isCompleted: i < 2, // First two sessions are completed
          exercises: [
            "Ball Control Drill",
            "Passing Exercise",
            "Shooting Practice"
          ],
          exerciseIds: List.generate(3, (j) => 'ex${j + 1}'),
        ),
      );
    }
    
    return sessions;
  }
  
  Future<TrainingPlan> generateTrainingPlan({
    required String focusArea,
    required int durationWeeks,
    required String playerLevel,
    required String goalDescription,
    required User user,
    required PlayerStats? playerStats,
  }) async {
    // In a real app, this would be a server call
    // For now, we'll generate a plan locally
    
    // Default to 6 weeks if not specified or invalid
    if (durationWeeks <= 0 || durationWeeks > 12) {
      durationWeeks = 6;
    }
    
    // Create a title based on focus area and user's name
    final title = '${user.fullName.split(' ')[0]}\'s ${focusArea} Development Plan';
    
    // Generate weeks with progressively increasing difficulty
    final weeks = List.generate(durationWeeks, (weekIndex) {
      final weekNumber = weekIndex + 1;
      final difficulty = _calculateWeekDifficulty(weekNumber, durationWeeks, playerLevel);
      
      return TrainingWeek(
        weekNumber: weekNumber,
        title: 'Week $weekNumber - ${_getWeekTitle(weekNumber, durationWeeks, focusArea)}',
        description: _generateWeekDescription(weekNumber, durationWeeks, focusArea, user.fullName),
        difficulty: difficulty,
        sessions: _generateSessions(weekNumber, durationWeeks, focusArea, difficulty, weekIndex),
      );
    });
    
    final now = DateTime.now();
    
    return TrainingPlan(
      id: 'tp_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id!,
      title: title,
      focusArea: [focusArea], // Convert to list
      playerLevel: playerLevel,
      startDate: now,
      endDate: now.add(Duration(days: durationWeeks * 7)),
      durationWeeks: durationWeeks,
      weeks: weeks,
      progress: 0,
      createdAt: now,
    );
  }
  
  Future<List<TrainingPlan>> getUserTrainingPlans() async {
    // In a real app, we would fetch from an API
    try {
      final user = await _authService.getCurrentUser();
      if (user.id == null) {
        throw Exception("User not found");
      }
      
      // Initialize mock data if empty
      if (_mockTrainingPlans.isEmpty) {
        _initMockData();
      }
      
      // Return plans for this user
      return _mockTrainingPlans.where((plan) => plan.userId == user.id).toList();
    } catch (e) {
      debugPrint("Error getting training plans: $e");
      _initMockData(); // Ensure mock data exists
      return _mockTrainingPlans;
    }
  }
  
  Future<TrainingPlan> getTrainingPlan(String planId) async {
    // Find plan by ID
    final planIndex = _mockTrainingPlans.indexWhere((plan) => plan.id == planId);
    if (planIndex == -1) {
      throw Exception("Training plan not found");
    }
    
    final plan = _mockTrainingPlans[planIndex];
    return plan;
  }
  
  Future<TrainingPlan> createTrainingPlan({
    required List<String> focusArea,
    required String playerLevel,
    required int durationWeeks,
  }) async {
    // Get current user
    final user = await _authService.getCurrentUser();
    
    // Create a new training plan
    final now = DateTime.now();
    final newPlan = TrainingPlan(
      id: "${_mockTrainingPlans.length + 1}", // Simple ID for mock data
      title: "${playerLevel.capitalize()} ${focusArea.join('/')} Program",
      focusArea: focusArea,
      playerLevel: playerLevel,
      startDate: now,
      endDate: now.add(Duration(days: 7 * durationWeeks)),
      weeks: _generateMockWeeks(durationWeeks),
      progress: 0,
      createdAt: now,
      userId: user.id ?? "1", // Use default if null
    );
    
    // Add to mock storage
    _mockTrainingPlans.add(newPlan);
    
    return newPlan;
  }
  
  Future<TrainingPlan> markSessionComplete(String planId, int weekIndex, int sessionIndex, bool isComplete) async {
    final planIndex = _mockTrainingPlans.indexWhere((plan) => plan.id == planId);
    if (planIndex == -1) {
      throw Exception("Training plan not found");
    }
    
    final plan = _mockTrainingPlans[planIndex];
    
    // Check bounds
    if (weekIndex < 0 || weekIndex >= plan.weeks.length) {
      throw Exception("Week index out of bounds");
    }
    
    // Create updated week
    final week = plan.weeks[weekIndex];
    if (sessionIndex < 0 || sessionIndex >= week.sessions.length) {
      throw Exception("Session index out of bounds");
    }
    
    // Create updated session
    final updatedSessions = [...week.sessions];
    updatedSessions[sessionIndex] = updatedSessions[sessionIndex].copyWith(
      isCompleted: isComplete
    );
    
    // Create updated week
    final updatedWeeks = [...plan.weeks];
    updatedWeeks[weekIndex] = week.copyWith(sessions: updatedSessions);
    
    // Create updated plan
    final updatedPlan = plan.copyWith(weeks: updatedWeeks);
    
    // Update storage
    _mockTrainingPlans[planIndex] = updatedPlan;
    
    // Update progress
    return updatePlanProgress(planId);
  }
  
  Future<TrainingPlan> updatePlanProgress(String planId) async {
    // Find plan by ID
    final planIndex = _mockTrainingPlans.indexWhere((plan) => plan.id == planId);
    if (planIndex == -1) {
      throw Exception("Training plan not found");
    }
    
    final plan = _mockTrainingPlans[planIndex];
    
    // Calculate progress
    int totalSessions = 0;
    int completedSessions = 0;
    
    for (final week in plan.weeks) {
      totalSessions += week.sessions.length as int;
      completedSessions += week.sessions.where((session) => session.isCompleted).length as int;
    }
    
    // Calculate percentage
    final newProgress = totalSessions > 0 
      ? ((completedSessions / totalSessions) * 100).round() 
      : 0;
    
    // Update plan
    _mockTrainingPlans[planIndex] = plan.copyWith(progress: newProgress);
    
    return _mockTrainingPlans[planIndex];
  }
  
  String _calculateWeekDifficulty(int weekNumber, int totalWeeks, String playerLevel) {
    // Early weeks are easier, later weeks get progressively harder
    if (weekNumber < totalWeeks / 3) {
      return playerLevel == 'Beginner' ? 'Beginner' : 'Easy';
    } else if (weekNumber < 2 * totalWeeks / 3) {
      return playerLevel == 'Advanced' ? 'Intermediate' : 'Intermediate';
    } else {
      return playerLevel == 'Beginner' ? 'Intermediate' : 'Advanced';
    }
  }
  
  String _getWeekTitle(int weekNumber, int totalWeeks, String focusArea) {
    if (weekNumber == 1) {
      return 'Foundation';
    } else if (weekNumber == totalWeeks) {
      return 'Mastery';
    } else if (weekNumber < totalWeeks / 2) {
      return 'Building Blocks';
    } else {
      return 'Advanced Techniques';
    }
  }
  
  String _generateWeekDescription(int weekNumber, int totalWeeks, String focusArea, String playerName) {
    if (weekNumber == 1) {
      return 'Let\'s build a strong foundation for your $focusArea skills, ${playerName.split(' ')[0]}. This week focuses on the fundamentals.';
    } else if (weekNumber == totalWeeks) {
      return 'This is your peak week, ${playerName.split(' ')[0]}! We\'ll push your $focusArea skills to the next level.';
    } else if (weekNumber < totalWeeks / 2) {
      return 'Week $weekNumber builds on your fundamentals with more advanced $focusArea drills. Keep pushing, ${playerName.split(' ')[0]}!';
    } else {
      return 'You\'re making great progress, ${playerName.split(' ')[0]}! These advanced $focusArea exercises will sharpen your skills further.';
    }
  }
  
  List<TrainingSession> _generateSessions(int weekNumber, int totalWeeks, String focusArea, String difficulty, int weekIndex) {
    // Number of sessions increases slightly as weeks progress
    final sessionCount = min(3 + (weekIndex ~/ 2), 5);
    
    // Create a random but consistent set of sessions for each week
    return List.generate(sessionCount, (sessionIndex) {
      final dayOfWeek = 1 + sessionIndex * 2; // Spread sessions through the week
      
      final sessionId = 'ts_${weekNumber}_${sessionIndex + 1}';
      final intensity = _calculateSessionIntensity(sessionIndex, sessionCount, weekNumber, totalWeeks);
      
      return TrainingSession(
        id: sessionId,
        title: '${_getSessionTitle(sessionIndex, focusArea, intensity)} - Day $dayOfWeek',
        description: _getSessionDescription(sessionIndex, weekNumber, focusArea, intensity),
        exerciseIds: _getExerciseIdsForSession(focusArea, sessionIndex, weekNumber),
        exercises: _getExerciseIdsForSession(focusArea, sessionIndex, weekNumber),
        intensity: intensity,
        durationMinutes: _getSessionDuration(intensity, weekNumber, totalWeeks),
      );
    });
  }
  
  String _calculateSessionIntensity(int sessionIndex, int sessionCount, int weekNumber, int totalWeeks) {
    // Intensity varies within the week and increases across weeks
    final weekProgress = weekNumber / totalWeeks;
    
    if (sessionIndex == 0) {
      // First session of the week is usually lighter
      return weekProgress > 0.7 ? 'Medium' : 'Low';
    } else if (sessionIndex == sessionCount - 1) {
      // Last session is the most intense
      return weekProgress > 0.3 ? 'High' : 'Medium';
    } else {
      // Middle sessions vary
      return sessionIndex % 2 == 0 ? 'Medium' : 'High';
    }
  }
  
  String _getSessionTitle(int sessionIndex, String focusArea, String intensity) {
    final titles = [
      '$focusArea Fundamentals',
      '$focusArea Technique Drills',
      '$focusArea Power Training',
      '$focusArea Precision Work',
      '$focusArea Speed Drills',
      '$focusArea Agility Session',
      '$focusArea Control Workshop',
    ];
    
    return titles[sessionIndex % titles.length];
  }
  
  String _getSessionDescription(int sessionIndex, int weekNumber, String focusArea, String intensity) {
    final baseDescriptions = [
      'Focus on the core techniques of $focusArea with targeted drills.',
      'Improve your $focusArea skills with progressive exercises.',
      'Build strength and power in your $focusArea abilities.',
      'Develop precision and accuracy in your $focusArea technique.',
      'Enhance your speed while maintaining quality in $focusArea drills.',
    ];
    
    final intensityDescriptions = {
      'Low': 'This is a lighter session focusing on technique and form.',
      'Medium': 'A balanced session with moderate intensity to build skill and endurance.',
      'High': 'High-intensity training to push your limits and improve performance.',
    };
    
    return '${baseDescriptions[sessionIndex % baseDescriptions.length]} ${intensityDescriptions[intensity]}';
  }
  
  List<String> _getExerciseIdsForSession(String focusArea, int sessionIndex, int weekNumber) {
    // In a real app, we would select appropriate exercises from the database
    // For now, return mock exercise IDs
    final count = 3 + (sessionIndex % 2); // 3-4 exercises per session
    
    return List.generate(count, (i) => 'ex${i + 1}');
  }
  
  int _getSessionDuration(String intensity, int weekNumber, int totalWeeks) {
    // Session duration increases with intensity and as weeks progress
    final baseMinutes = {
      'Low': 30,
      'Medium': 45,
      'High': 60,
    }[intensity] ?? 45;
    
    // Add 5 minutes for each third of the program completed
    final weekMultiplier = (weekNumber / (totalWeeks / 3)).floor();
    
    return baseMinutes + (weekMultiplier * 5);
  }
}

// Helper extension
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
} 