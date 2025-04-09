import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_plan.dart';
import '../models/exercise.dart';

class TrainingPlanService {
  static const String _apiBaseUrl = 'http://localhost:8001';
  static const String _trainingPlansEndpoint = '/training-plans';
  static const String _localStorageKey = 'training_plan';

  // Get a user's training plan
  static Future<TrainingPlan> getTrainingPlan() async {
    try {
      // In a real app, fetch from API with authentication
      // final response = await http.get(
      //   Uri.parse('$_apiBaseUrl$_trainingPlansEndpoint'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );
      
      // For now, fetch from local storage or create empty one
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_localStorageKey);
      
      if (json != null) {
        return TrainingPlan.fromJson(jsonDecode(json));
      } else {
        return TrainingPlan.empty();
      }
    } catch (e) {
      print('Error fetching training plan: $e');
      return TrainingPlan.empty();
    }
  }

  // Save training plan
  static Future<bool> saveTrainingPlan(TrainingPlan plan) async {
    try {
      // In a real app, save to API
      // final response = await http.post(
      //   Uri.parse('$_apiBaseUrl$_trainingPlansEndpoint'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode(plan.toJson()),
      // );
      
      // For now, save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localStorageKey, jsonEncode(plan.toJson()));
      return true;
    } catch (e) {
      print('Error saving training plan: $e');
      return false;
    }
  }

  // Get mockup training plan - for development purposes
  static Future<TrainingPlan> getMockTrainingPlan() async {
    final mockExercises = _getMockExercises();
    
    // Create a sample training plan with exercises for each day
    final TrainingPlan plan = TrainingPlan(
      id: 'mock-plan-1',
      title: 'Weekly Training Plan',
      description: 'Improve your ball control and shooting',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      schedule: {
        'Monday': [mockExercises[0], mockExercises[1]],
        'Wednesday': [mockExercises[2], mockExercises[3]],
        'Friday': [mockExercises[4], mockExercises[5]],
        'Saturday': [mockExercises[6]],
      },
      trainingDays: ['Monday', 'Wednesday', 'Friday', 'Saturday'],
    );
    
    return plan;
  }
  
  // Generate mock exercises for development
  static List<TrainingPlanExercise> _getMockExercises() {
    return [
      TrainingPlanExercise(
        id: 'ex1',
        title: 'Cone Dribbling',
        description: 'Dribble through a set of cones to improve close control',
        category: 'Dribbling',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/dribbling1.mp4',
        imageUrl: 'assets/images/exercises/dribbling1.jpg',
        durationMinutes: 15,
        equipment: ['Cones', 'Ball'],
        skills: ['Ball Control', 'Agility'],
      ),
      TrainingPlanExercise(
        id: 'ex2',
        title: 'Short Passing Drill',
        description: 'Practice short passing with a partner to improve accuracy',
        category: 'Passing',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/passing1.mp4',
        imageUrl: 'assets/images/exercises/passing1.jpg',
        durationMinutes: 20,
        equipment: ['Ball'],
        skills: ['Passing', 'Communication'],
      ),
      TrainingPlanExercise(
        id: 'ex3',
        title: 'Shooting Practice',
        description: 'Practice shooting from various positions',
        category: 'Shooting',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/shooting1.mp4',
        imageUrl: 'assets/images/exercises/shooting1.jpg',
        durationMinutes: 25,
        equipment: ['Ball', 'Goal'],
        skills: ['Shooting', 'Technique'],
      ),
      TrainingPlanExercise(
        id: 'ex4',
        title: 'High-Intensity Interval Training',
        description: 'Improve stamina and endurance with high-intensity intervals',
        category: 'Fitness',
        difficulty: 'Advanced',
        videoUrl: 'https://example.com/videos/fitness1.mp4',
        imageUrl: 'assets/images/exercises/fitness1.jpg',
        durationMinutes: 30,
        equipment: ['Cones'],
        skills: ['Stamina', 'Speed'],
      ),
      TrainingPlanExercise(
        id: 'ex5',
        title: 'Free Kick Practice',
        description: 'Improve your free kick technique',
        category: 'Set Pieces',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/freekick1.mp4',
        imageUrl: 'assets/images/exercises/freekick1.jpg',
        durationMinutes: 20,
        equipment: ['Ball', 'Goal', 'Wall Dummies'],
        skills: ['Free Kicks', 'Technique'],
      ),
      TrainingPlanExercise(
        id: 'ex6',
        title: 'Defensive Positioning',
        description: 'Learn proper defensive positioning and tackling technique',
        category: 'Defense',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/defense1.mp4',
        imageUrl: 'assets/images/exercises/defense1.jpg',
        durationMinutes: 25,
        equipment: ['Cones', 'Ball'],
        skills: ['Defending', 'Positioning'],
      ),
      TrainingPlanExercise(
        id: 'ex7',
        title: 'Match Simulation',
        description: 'Small-sided game to apply skills in a match situation',
        category: 'Game Situations',
        difficulty: 'Advanced',
        videoUrl: 'https://example.com/videos/match1.mp4',
        imageUrl: 'assets/images/exercises/match1.jpg',
        durationMinutes: 45,
        equipment: ['Ball', 'Cones', 'Goals'],
        skills: ['Game Intelligence', 'Team Play'],
      ),
    ];
  }
} 