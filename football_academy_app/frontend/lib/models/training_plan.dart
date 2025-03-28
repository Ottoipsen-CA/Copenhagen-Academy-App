import 'package:flutter/material.dart';

@immutable
class TrainingPlan {
  final String id;
  final String userId;
  final String title;
  final List<String> focusArea;
  final String playerLevel;
  final DateTime startDate;
  final DateTime endDate;
  final int progress;
  final List<TrainingWeek> weeks;
  final DateTime createdAt;
  final int durationWeeks;

  const TrainingPlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.focusArea,
    required this.playerLevel,
    required this.startDate,
    required this.endDate,
    this.progress = 0,
    required this.weeks,
    required this.createdAt,
    required this.durationWeeks,
  });

  // Copy with constructor for immutability
  TrainingPlan copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? focusArea,
    String? playerLevel,
    DateTime? startDate,
    DateTime? endDate,
    int? progress,
    List<TrainingWeek>? weeks,
    DateTime? createdAt,
    int? durationWeeks,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      focusArea: focusArea ?? this.focusArea,
      playerLevel: playerLevel ?? this.playerLevel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      weeks: weeks ?? this.weeks,
      createdAt: createdAt ?? this.createdAt,
      durationWeeks: durationWeeks ?? this.durationWeeks,
    );
  }

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'focusArea': focusArea,
      'playerLevel': playerLevel,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'progress': progress,
      'weeks': weeks.map((week) => week.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'durationWeeks': durationWeeks,
    };
  }

  // From JSON constructor
  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      focusArea: (json['focusArea'] as List<dynamic>).map((e) => e as String).toList(),
      playerLevel: json['playerLevel'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      progress: json['progress'] as int? ?? 0,
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => TrainingWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      durationWeeks: json['durationWeeks'] as int,
    );
  }
}

@immutable
class TrainingWeek {
  final int weekNumber;
  final String title;
  final String description;
  final String difficulty;
  final List<TrainingSession> sessions;

  const TrainingWeek({
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.sessions,
  });

  // Copy with constructor
  TrainingWeek copyWith({
    int? weekNumber,
    String? title,
    String? description,
    String? difficulty,
    List<TrainingSession>? sessions,
  }) {
    return TrainingWeek(
      weekNumber: weekNumber ?? this.weekNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      sessions: sessions ?? this.sessions,
    );
  }

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'sessions': sessions.map((session) => session.toJson()).toList(),
    };
  }

  // From JSON constructor
  factory TrainingWeek.fromJson(Map<String, dynamic> json) {
    return TrainingWeek(
      weekNumber: json['weekNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class TrainingSession {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final String intensity;
  final bool isCompleted;
  final List<String> exercises;
  final List<String> exerciseIds;

  const TrainingSession({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.intensity,
    this.isCompleted = false,
    required this.exercises,
    required this.exerciseIds,
  });

  // Copy with constructor
  TrainingSession copyWith({
    String? id,
    String? title,
    String? description,
    int? durationMinutes,
    String? intensity,
    bool? isCompleted,
    List<String>? exercises,
    List<String>? exerciseIds,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      isCompleted: isCompleted ?? this.isCompleted,
      exercises: exercises ?? this.exercises,
      exerciseIds: exerciseIds ?? this.exerciseIds,
    );
  }

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'intensity': intensity,
      'isCompleted': isCompleted,
      'exercises': exercises,
      'exerciseIds': exerciseIds,
    };
  }

  // From JSON constructor
  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: json['durationMinutes'] as int,
      intensity: json['intensity'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      exercises: (json['exercises'] as List<dynamic>).map((e) => e as String).toList(),
      exerciseIds: (json['exerciseIds'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Color getIntensityColor() {
    switch (intensity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
} 