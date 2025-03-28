import 'package:flutter/foundation.dart';
import 'exercise.dart';

@immutable
class TrainingPlan {
  final String? id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, List<TrainingPlanExercise>> schedule; // Map of day -> exercises
  final List<String> trainingDays; // Days of the week set for training
  
  const TrainingPlan({
    this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.schedule,
    required this.trainingDays,
  });
  
  factory TrainingPlan.create({
    required String title,
    required String description,
    List<String> trainingDays = const [],
  }) {
    final now = DateTime.now();
    return TrainingPlan(
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
      schedule: {},
      trainingDays: trainingDays,
    );
  }
  
  // Create an empty training plan for a specific day
  factory TrainingPlan.empty() {
    final now = DateTime.now();
    return TrainingPlan(
      title: 'My Weekly Training Plan',
      description: 'Custom training plan to improve your skills',
      createdAt: now,
      updatedAt: now,
      schedule: {},
      trainingDays: [],
    );
  }
  
  // Helper method to get all weekdays
  static List<String> get allWeekdays => [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  // Add exercise to a specific day
  TrainingPlan addExercise(String day, TrainingPlanExercise exercise) {
    final updatedSchedule = Map<String, List<TrainingPlanExercise>>.from(schedule);
    
    if (updatedSchedule.containsKey(day)) {
      updatedSchedule[day] = [...updatedSchedule[day]!, exercise];
    } else {
      updatedSchedule[day] = [exercise];
    }
    
    return TrainingPlan(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      schedule: updatedSchedule,
      trainingDays: trainingDays,
    );
  }
  
  // Remove exercise from a specific day
  TrainingPlan removeExercise(String day, TrainingPlanExercise exercise) {
    if (!schedule.containsKey(day)) {
      return this;
    }
    
    final updatedSchedule = Map<String, List<TrainingPlanExercise>>.from(schedule);
    updatedSchedule[day] = updatedSchedule[day]!.where((e) => e.id != exercise.id).toList();
    
    return TrainingPlan(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      schedule: updatedSchedule,
      trainingDays: trainingDays,
    );
  }
  
  // Add a training day
  TrainingPlan addTrainingDay(String day) {
    if (trainingDays.contains(day)) {
      return this;
    }
    
    return TrainingPlan(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      schedule: schedule,
      trainingDays: [...trainingDays, day],
    );
  }
  
  // Remove a training day
  TrainingPlan removeTrainingDay(String day) {
    if (!trainingDays.contains(day)) {
      return this;
    }
    
    // Remove the day from trainingDays and remove all exercises for that day
    final updatedSchedule = Map<String, List<TrainingPlanExercise>>.from(schedule);
    updatedSchedule.remove(day);
    
    return TrainingPlan(
      id: id,
      title: title,
      description: description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      schedule: updatedSchedule,
      trainingDays: trainingDays.where((d) => d != day).toList(),
    );
  }
  
  // Calculate total duration for a specific day
  int getDayDuration(String day) {
    if (!schedule.containsKey(day)) {
      return 0;
    }
    
    return schedule[day]!.fold(0, (sum, exercise) => sum + exercise.durationMinutes);
  }
  
  // Get exercises for a specific day
  List<TrainingPlanExercise> getExercisesForDay(String day) {
    return schedule[day] ?? [];
  }
  
  // Get total number of exercises in the plan
  int get totalExercises {
    return schedule.values.fold(0, (sum, exercises) => sum + exercises.length);
  }
  
  // Get total duration of the plan (in minutes)
  int get totalDuration {
    return schedule.values.fold(0, (sum, exercises) => 
      sum + exercises.fold(0, (exerciseSum, exercise) => exerciseSum + exercise.durationMinutes));
  }
  
  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    // Convert schedule from JSON to Map<String, List<TrainingPlanExercise>>
    final Map<String, List<TrainingPlanExercise>> schedule = {};
    if (json['schedule'] != null) {
      (json['schedule'] as Map<String, dynamic>).forEach((day, exercises) {
        schedule[day] = (exercises as List)
            .map((e) => TrainingPlanExercise.fromJson(e))
            .toList();
      });
    }
    
    return TrainingPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      schedule: schedule,
      trainingDays: (json['trainingDays'] as List).cast<String>(),
    );
  }
  
  Map<String, dynamic> toJson() {
    // Convert schedule to JSON format
    final Map<String, dynamic> scheduleJson = {};
    schedule.forEach((day, exercises) {
      scheduleJson[day] = exercises.map((e) => e.toJson()).toList();
    });
    
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'schedule': scheduleJson,
      'trainingDays': trainingDays,
    };
  }
}

@immutable
class TrainingPlanExercise {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String? videoUrl;
  final String? imageUrl;
  final int durationMinutes;
  final List<String>? equipment;
  final List<String>? skills;
  
  const TrainingPlanExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.videoUrl,
    this.imageUrl,
    required this.durationMinutes,
    this.equipment,
    this.skills,
  });
  
  // Create a TrainingPlanExercise from an Exercise
  factory TrainingPlanExercise.fromExercise(Exercise exercise) {
    return TrainingPlanExercise(
      id: exercise.id ?? 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      title: exercise.title,
      description: exercise.description,
      category: exercise.category,
      difficulty: exercise.difficulty,
      videoUrl: exercise.videoUrl,
      imageUrl: exercise.imageUrl,
      durationMinutes: exercise.durationMinutes,
      equipment: exercise.equipment,
      skills: exercise.skills,
    );
  }
  
  factory TrainingPlanExercise.fromJson(Map<String, dynamic> json) {
    return TrainingPlanExercise(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      durationMinutes: json['durationMinutes'],
      equipment: json['equipment'] != null ? (json['equipment'] as List).cast<String>() : null,
      skills: json['skills'] != null ? (json['skills'] as List).cast<String>() : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'durationMinutes': durationMinutes,
      'equipment': equipment,
      'skills': skills,
    };
  }
} 