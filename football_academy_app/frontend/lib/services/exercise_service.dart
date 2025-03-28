import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/exercise.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class ExerciseService {
  final AuthService _authService;
  // Use a class field to store mock exercises so changes persist
  final List<Exercise> _mockExercises = [];
  bool _initialized = false;
  
  ExerciseService(this._authService) {
    _initializeMockData();
  }
  
  Future<List<Exercise>> getExercises({
    String? category,
    String? difficulty,
    String? search,
    List<String>? skills,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      // Apply filters
      List<Exercise> filteredExercises = List.from(_mockExercises);
      
      if (category != null) {
        filteredExercises = filteredExercises.where((e) => e.category == category).toList();
      }
      
      if (difficulty != null) {
        filteredExercises = filteredExercises.where((e) => e.difficulty == difficulty).toList();
      }
      
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        filteredExercises = filteredExercises.where((e) =>
          e.title.toLowerCase().contains(searchLower) ||
          e.description.toLowerCase().contains(searchLower)
        ).toList();
      }
      
      if (skills != null && skills.isNotEmpty) {
        filteredExercises = filteredExercises.where((e) =>
          e.skills != null &&
          skills.any((skill) => e.skills!.contains(skill))
        ).toList();
      }
      
      return filteredExercises;
    } catch (e) {
      throw Exception('Failed to load exercises: $e');
    }
  }
  
  Future<Exercise> getExercise(int id) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // In a real app, we would call the API
      // For now, return mock data
      final exercise = _mockExercises.firstWhere(
        (exercise) => exercise.id == id.toString(),
        orElse: () => throw Exception('Exercise not found with ID: $id'),
      );
      
      return exercise;
    } catch (e) {
      throw Exception('Failed to fetch exercise: $e');
    }
  }
  
  Future<Exercise> toggleFavorite(int id) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Find exercise by ID
      final index = _mockExercises.indexWhere((exercise) => exercise.id == id.toString());
      
      if (index == -1) {
        throw Exception('Exercise not found with ID: $id');
      }
      
      // Toggle favorite status
      final exercise = _mockExercises[index];
      final updatedExercise = exercise.copyWith(
        isFavorite: !exercise.isFavorite,
      );
      
      // Update in mock data
      _mockExercises[index] = updatedExercise;
      
      return updatedExercise;
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }
  
  Future<List<Exercise>> getFavorites() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      return _mockExercises.where((e) => e.isFavorite).toList();
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }
  
  void _initializeMockData() {
    if (_initialized) return;
    
    _initialized = true;
    _mockExercises.addAll([
      Exercise(
        id: 'ex1',
        title: 'Precision Dribbling Circuit',
        description: 'Improve close ball control with this cone-based dribbling exercise. Players navigate through a series of cones using various techniques to enhance their close control and agility.',
        category: 'Dribbling',
        difficulty: 'Intermediate',
        videoUrl: 'https://www.youtube.com/watch?v=q1wTPYLKlBM',
        imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=1976&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 15,
        equipment: ['Cones', 'Balls'],
        skills: ['Ball Control', 'Agility', 'Coordination'],
        isFavorite: true,
        createdBy: 'Coach Thomas',
        createdAt: DateTime(2023, 3, 15),
      ),
      Exercise(
        id: 'ex2',
        title: 'Passing Triangle',
        description: 'Three players form a triangle and practice quick, one-touch passing. Focus on accuracy, proper weight, and using both feet. Increase difficulty by adding movement or reducing touches.',
        category: 'Passing',
        difficulty: 'Beginner',
        videoUrl: 'https://www.youtube.com/watch?v=LoJ5dsFz59s',
        imageUrl: 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?q=80&w=2049&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 20,
        equipment: ['Balls'],
        skills: ['Passing Accuracy', 'First Touch', 'Communication'],
        isFavorite: false,
        createdBy: 'Coach Sarah',
        createdAt: DateTime(2023, 4, 10),
      ),
      Exercise(
        id: 'ex3',
        title: 'Shooting Accuracy Challenge',
        description: 'Players take shots from various positions, aiming at targets in the goal. This exercise focuses on accuracy, technique, and finishing under pressure.',
        category: 'Shooting',
        difficulty: 'Intermediate',
        videoUrl: 'https://www.youtube.com/watch?v=VqcyMJHdE0Y',
        imageUrl: 'https://images.unsplash.com/photo-1552667466-07770ae110d0?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 25,
        equipment: ['Balls', 'Goal', 'Target markers'],
        skills: ['Finishing', 'Shooting Technique', 'Mental Focus'],
        isFavorite: true,
        createdBy: 'Coach Michael',
        createdAt: DateTime(2023, 2, 22),
      ),
      Exercise(
        id: 'ex4',
        title: 'Defensive Positioning Drill',
        description: 'Work on proper defensive stance, positioning, and footwork. Players learn to contain attackers and time their tackles effectively.',
        category: 'Defending',
        difficulty: 'Advanced',
        videoUrl: 'https://www.youtube.com/watch?v=KRSmAVS_V7c',
        imageUrl: 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?q=80&w=2049&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 30,
        equipment: ['Cones', 'Balls', 'Bibs'],
        skills: ['Tackling', 'Positioning', 'Reaction Time'],
        isFavorite: false,
        createdBy: 'Coach James',
        createdAt: DateTime(2023, 5, 5),
      ),
      Exercise(
        id: 'ex5',
        title: 'High-Intensity Shuttle Runs',
        description: 'Improve speed, agility, and endurance with timed shuttle runs. Players sprint between markers, working at maximum effort with short recovery periods.',
        category: 'Physical',
        difficulty: 'Advanced',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1550259979-ed79b48d2a30?q=80&w=1968&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 20,
        equipment: ['Cones', 'Stopwatch'],
        skills: ['Speed', 'Stamina', 'Agility'],
        isFavorite: false,
        createdBy: 'Coach Emma',
        createdAt: DateTime(2023, 1, 18),
      ),
      Exercise(
        id: 'ex6',
        title: 'First Touch Improvement',
        description: 'Focus on controlling the ball efficiently with various body parts. Partners serve balls of different heights and speeds to practice different control techniques.',
        category: 'Ball Control',
        difficulty: 'Beginner',
        videoUrl: 'https://www.youtube.com/watch?v=V0X2M9WGbSw',
        imageUrl: 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?q=80&w=2029&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 15,
        equipment: ['Balls'],
        skills: ['First Touch', 'Control', 'Awareness'],
        isFavorite: true,
        createdBy: 'Coach David',
        createdAt: DateTime(2023, 6, 12),
      ),
      Exercise(
        id: 'ex7',
        title: '1v1 Attacking Scenarios',
        description: 'Practice beating defenders in one-on-one situations. Focus on using feints, changes of pace, and technical skills to get past opponents.',
        category: 'Dribbling',
        difficulty: 'Intermediate',
        videoUrl: 'https://www.youtube.com/watch?v=MpWOBQs6UQc',
        imageUrl: 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 25,
        equipment: ['Cones', 'Balls', 'Mini Goals'],
        skills: ['Dribbling', 'Creativity', 'Decision Making'],
        isFavorite: false,
        createdBy: 'Coach Ryan',
        createdAt: DateTime(2023, 7, 7),
      ),
      Exercise(
        id: 'ex8',
        title: 'Passing and Moving',
        description: 'Emphasize the importance of moving after making a pass. Players work in groups, passing and then immediately moving to a new position to receive again.',
        category: 'Passing',
        difficulty: 'Beginner',
        videoUrl: null,
        imageUrl: 'https://via.placeholder.com/300x200?text=Passing+and+Moving',
        durationMinutes: 20,
        equipment: ['Balls', 'Bibs'],
        skills: ['Passing', 'Movement', 'Teamwork'],
        isFavorite: false,
        createdBy: 'Coach Anna',
        createdAt: DateTime(2023, 8, 14),
      ),
      // New exercises for additional categories
      Exercise(
        id: 'ex9',
        title: 'Sprint Training',
        description: 'Develop straight-line speed with these progressive sprint exercises. Perfect for enhancing acceleration and top-end speed over various distances.',
        category: 'Pace',
        difficulty: 'Advanced',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=2069&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 25,
        equipment: ['Cones', 'Stopwatch'],
        skills: ['Speed', 'Acceleration', 'Explosiveness'],
        isFavorite: false,
        createdBy: 'Coach Max',
        createdAt: DateTime(2023, 7, 5),
      ),
      Exercise(
        id: 'ex10',
        title: 'Balance and Coordination Drill',
        description: 'Improve general body control with this sequence of balance-focused exercises. Crucial for maintaining stability during complex movements.',
        category: 'Body Movements',
        difficulty: 'Intermediate',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 20,
        equipment: ['Balance board', 'Agility ladder'],
        skills: ['Balance', 'Coordination', 'Body Control'],
        isFavorite: false,
        createdBy: 'Coach Laura',
        createdAt: DateTime(2023, 8, 12),
      ),
      Exercise(
        id: 'ex11',
        title: 'Strength Training Circuit',
        description: 'Full-body strength training circuit designed specifically for footballers. Focuses on building functional strength for improved performance and injury prevention.',
        category: 'Physical',
        difficulty: 'Advanced',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1579126038374-6064e9370f0f?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 40,
        equipment: ['Weights', 'Resistance Bands', 'Medicine Balls'],
        skills: ['Strength', 'Power', 'Endurance'],
        isFavorite: false,
        createdBy: 'Coach Jason',
        createdAt: DateTime(2023, 11, 8),
      ),
      Exercise(
        id: 'ex12',
        title: 'Shooting Power Development',
        description: 'Focus on generating maximum power in shots while maintaining accuracy. Uses various techniques and drills to improve shooting mechanics and power generation.',
        category: 'Shooting',
        difficulty: 'Advanced',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=2187&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 30,
        equipment: ['Balls', 'Goal', 'Resistance Bands'],
        skills: ['Shooting Power', 'Technique', 'Core Strength'],
        isFavorite: true,
        createdBy: 'Coach Carlos',
        createdAt: DateTime(2023, 12, 3),
      ),
      Exercise(
        id: 'ex13',
        title: 'Dynamic Body Feints',
        description: 'Learn various body feints and movements to deceive defenders. This exercise focuses on the subtle body movements that create space and beat opponents.',
        category: 'Body Movements',
        difficulty: 'Intermediate',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1551958219-acbc608c6377?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 25,
        equipment: ['Cones', 'Balls'],
        skills: ['Deception', 'Agility', 'Creativity'],
        isFavorite: false,
        createdBy: 'Coach Luis',
        createdAt: DateTime(2024, 1, 15),
      ),
      Exercise(
        id: 'ex14',
        title: 'Tackling Technique Workshop',
        description: 'Master the art of clean, effective tackling with proper body position and timing. Focuses on winning the ball safely while minimizing fouls.',
        category: 'Defending',
        difficulty: 'Intermediate',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=1976&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 30,
        equipment: ['Balls', 'Training Mannequins', 'Bibs'],
        skills: ['Tackling', 'Timing', 'Defensive Positioning'],
        isFavorite: false,
        createdBy: 'Coach Pavel',
        createdAt: DateTime(2024, 2, 7),
      ),
      Exercise(
        id: 'ex15',
        title: 'Agility Ladder Drills',
        description: 'Comprehensive set of agility ladder exercises to develop quick feet, coordination and body control. Fundamental for improving overall speed and agility on the pitch.',
        category: 'Pace',
        difficulty: 'Beginner',
        videoUrl: null,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3',
        durationMinutes: 20,
        equipment: ['Agility Ladder', 'Cones'],
        skills: ['Footwork', 'Agility', 'Coordination'],
        isFavorite: true,
        createdBy: 'Coach Sophie',
        createdAt: DateTime(2024, 3, 1),
      ),
    ]);
  }
} 