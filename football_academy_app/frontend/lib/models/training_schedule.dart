import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class TrainingDay {
  final String? id;
  final String day;
  final List<TrainingSession> sessions;
  final List<Match> matches;
  final String? notes;
  final String? goals;

  const TrainingDay({
    this.id,
    required this.day,
    this.sessions = const [],
    this.matches = const [],
    this.notes,
    this.goals,
  });

  TrainingDay copyWith({
    String? id,
    String? day,
    List<TrainingSession>? sessions,
    List<Match>? matches,
    String? notes,
    String? goals,
  }) {
    return TrainingDay(
      id: id ?? this.id,
      day: day ?? this.day,
      sessions: sessions ?? this.sessions,
      matches: matches ?? this.matches,
      notes: notes ?? this.notes,
      goals: goals ?? this.goals,
    );
  }

  static List<String> get weekdays => [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  factory TrainingDay.fromJson(Map<String, dynamic> json) {
    return TrainingDay(
      id: json['id'],
      day: json['day'],
      sessions: (json['sessions'] as List?)
          ?.map((e) => TrainingSession.fromJson(e))
          .toList() ?? [],
      matches: (json['matches'] as List?)
          ?.map((e) => Match.fromJson(e))
          .toList() ?? [],
      notes: json['notes'],
      goals: json['goals'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'matches': matches.map((e) => e.toJson()).toList(),
      'notes': notes,
      'goals': goals,
    };
  }
}

@immutable
class TrainingSession {
  final String? id;
  final String title;
  final String? description;
  final String startTime; // Changed from TimeOfDay to String for simplicity
  final String endTime;   // Changed from TimeOfDay to String for simplicity
  final String? location;
  final String? type; // e.g., Individual, Team, Recovery
  final int intensity; // 1-5 scale
  final String? preEvaluation; // Player's goals before training
  final String? postEvaluation; // Player's reflection after training
  
  const TrainingSession({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.type,
    this.intensity = 3,
    this.preEvaluation,
    this.postEvaluation,
  });

  int get durationMinutes {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    return (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
  }

  String get timeRange {
    return '$startTime - $endTime';
  }

  TrainingSession copyWith({
    String? id,
    String? title,
    String? description,
    String? startTime,
    String? endTime,
    String? location,
    String? type,
    int? intensity,
    String? preEvaluation,
    String? postEvaluation,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      preEvaluation: preEvaluation ?? this.preEvaluation,
      postEvaluation: postEvaluation ?? this.postEvaluation,
    );
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
      type: json['type'],
      intensity: json['intensity'] ?? 3,
      preEvaluation: json['preEvaluation'],
      postEvaluation: json['postEvaluation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'type': type,
      'intensity': intensity,
      'preEvaluation': preEvaluation,
      'postEvaluation': postEvaluation,
    };
  }
}

@immutable
class Match {
  final String? id;
  final String opponent;
  final bool isHomeGame;  // Changed from isHome to isHomeGame
  final DateTime dateTime;
  final String? location;
  final String? competition; // e.g., League, Cup, Friendly
  
  const Match({
    this.id,
    required this.opponent,
    required this.isHomeGame, // Changed from isHome to isHomeGame
    required this.dateTime,
    this.location,
    this.competition,
  });

  String get matchTitle => isHomeGame ? 'vs $opponent (H)' : 'vs $opponent (A)';

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      opponent: json['opponent'],
      isHomeGame: json['isHomeGame'],
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'],
      competition: json['competition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'opponent': opponent,
      'isHomeGame': isHomeGame,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'competition': competition,
    };
  }
}

@immutable
class WeeklyTrainingSchedule {
  final String? id;
  final String title;
  final DateTime weekStartDate;
  final List<TrainingDay> days;
  final String? weeklyGoals;
  
  const WeeklyTrainingSchedule({
    this.id,
    required this.title,
    required this.weekStartDate, 
    required this.days,
    this.weeklyGoals,
  });

  // Create an empty schedule with all days of the week
  factory WeeklyTrainingSchedule.createEmpty({
    String title = 'My Weekly Schedule',
    DateTime? startDate,
  }) {
    final weekStart = startDate ?? DateTime.now();
    // Find the Monday of the current week
    final daysToSubtract = weekStart.weekday - 1;
    final monday = weekStart.subtract(Duration(days: daysToSubtract));
    
    return WeeklyTrainingSchedule(
      title: title,
      weekStartDate: monday,
      days: TrainingDay.weekdays.map((day) => 
        TrainingDay(day: day)
      ).toList(),
    );
  }

  WeeklyTrainingSchedule copyWith({
    String? id,
    String? title,
    DateTime? weekStartDate,
    List<TrainingDay>? days,
    String? weeklyGoals,
  }) {
    return WeeklyTrainingSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      days: days ?? this.days,
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
    );
  }

  // Update a specific day in the schedule
  WeeklyTrainingSchedule updateDay(TrainingDay updatedDay) {
    final newDays = days.map((day) => 
      day.day == updatedDay.day ? updatedDay : day
    ).toList();
    
    return copyWith(days: newDays);
  }

  factory WeeklyTrainingSchedule.fromJson(Map<String, dynamic> json) {
    return WeeklyTrainingSchedule(
      id: json['id'],
      title: json['title'],
      weekStartDate: DateTime.parse(json['weekStartDate']),
      days: (json['days'] as List)
          .map((e) => TrainingDay.fromJson(e))
          .toList(),
      weeklyGoals: json['weeklyGoals'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weekStartDate': weekStartDate.toIso8601String(),
      'days': days.map((e) => e.toJson()).toList(),
      'weeklyGoals': weeklyGoals,
    };
  }
} 