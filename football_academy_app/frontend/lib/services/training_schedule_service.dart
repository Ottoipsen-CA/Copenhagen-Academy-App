import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_schedule.dart';
import 'package:flutter/material.dart';

class TrainingScheduleService {
  static const String _scheduleKey = 'training_schedule';
  
  // Get the current schedule or create a new one if none exists
  static Future<WeeklyTrainingSchedule> getCurrentSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = prefs.getString(_scheduleKey);
    
    if (scheduleJson != null) {
      try {
        return WeeklyTrainingSchedule.fromJson(json.decode(scheduleJson));
      } catch (e) {
        print('Error loading schedule: $e');
      }
    }
    
    // Return a mock schedule if none exists
    return _createMockSchedule();
  }
  
  // Save the schedule
  static Future<void> saveSchedule(WeeklyTrainingSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scheduleKey, json.encode(schedule.toJson()));
  }
  
  // Create a new mock schedule for demonstration
  static WeeklyTrainingSchedule _createMockSchedule() {
    final schedule = WeeklyTrainingSchedule.createEmpty(
      title: 'My Training Week',
    );
    
    // Add some mock sessions and matches
    final mondaySessions = [
      TrainingSession(
        title: 'Morning Run',
        startTime: '08:00',
        endTime: '09:00',
        intensity: 2,
        type: 'Cardio',
        location: 'City Park',
      ),
      TrainingSession(
        title: 'Team Training',
        startTime: '18:00',
        endTime: '20:00',
        intensity: 4,
        type: 'Technical',
        location: 'Main Field',
        description: 'Focus on passing and movement',
      ),
    ];
    
    final wednesdaySessions = [
      TrainingSession(
        title: 'Strength Training',
        startTime: '16:00',
        endTime: '17:30',
        intensity: 5,
        type: 'Physical',
        location: 'Gym',
      ),
    ];
    
    final thursdaySessions = [
      TrainingSession(
        title: 'Team Training',
        startTime: '18:00',
        endTime: '20:00',
        intensity: 3,
        type: 'Tactical',
        location: 'Main Field',
        description: 'Match preparation',
      ),
    ];

    final fridaySessions = [
      TrainingSession(
        title: 'Recovery Session',
        startTime: '14:00',
        endTime: '15:00',
        intensity: 1,
        type: 'Recovery',
        location: 'Spa Center',
        description: 'Light stretching and swimming',
      ),
    ];
    
    // Create mock matches
    final saturdayMatch = Match(
      opponent: 'City FC',
      isHomeGame: true,
      dateTime: DateTime.now().add(const Duration(days: 5, hours: 15)),
      location: 'Home Stadium',
      competition: 'League',
      description: 'Important league match against a strong opponent',
      preMatchNotes: 'Focus on defensive stability and counter-attacks',
      preMatchRating: 4,
    );
    
    final wednesdayMatch = Match(
      opponent: 'United SC',
      isHomeGame: false,
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 18)),
      location: 'Away Stadium',
      competition: 'Cup',
      description: 'First round of the cup competition',
      preMatchNotes: 'Rest key players, give youth a chance',
      preMatchRating: 3,
      postMatchAnalysis: 'Good performance from the young players',
      postMatchRating: 4,
    );
    
    final sundayMatch = Match(
      opponent: 'Academy FC',
      isHomeGame: true,
      dateTime: DateTime.now().add(const Duration(days: 6, hours: 12)),
      location: 'Training Ground',
      competition: 'Friendly',
      description: 'Preparation match for next week',
      performanceRating: 3,
    );
    
    // Update the days in the schedule
    final days = schedule.days.map((day) {
      switch (day.day) {
        case 'Monday':
          return day.copyWith(sessions: mondaySessions);
        case 'Wednesday':
          return day.copyWith(sessions: wednesdaySessions, matches: [wednesdayMatch]);
        case 'Thursday':
          return day.copyWith(sessions: thursdaySessions);
        case 'Friday':
          return day.copyWith(sessions: fridaySessions);
        case 'Saturday':
          return day.copyWith(matches: [saturdayMatch]);
        case 'Sunday':
          return day.copyWith(matches: [sundayMatch]);
        default:
          return day;
      }
    }).toList();
    
    return schedule.copyWith(
      days: days,
      weeklyGoals: 'Improve passing accuracy and team movement. Prepare for Saturday\'s match against City FC.',
    );
  }
  
  // Add a new training session to a specific day
  static Future<TrainingDay> addTrainingSession(
    WeeklyTrainingSchedule schedule,
    TrainingDay day,
    TrainingSession session,
  ) async {
    final updatedSessions = List<TrainingSession>.from(day.sessions)
      ..add(session);
    
    final updatedDay = day.copyWith(sessions: updatedSessions);
    final updatedSchedule = schedule.updateDay(updatedDay);
    
    await saveSchedule(updatedSchedule);
    return updatedDay;
  }
  
  // Add a new match to a specific day
  static Future<TrainingDay> addMatch(
    WeeklyTrainingSchedule schedule,
    TrainingDay day,
    Match match,
  ) async {
    final updatedMatches = List<Match>.from(day.matches)
      ..add(match);
    
    final updatedDay = day.copyWith(matches: updatedMatches);
    final updatedSchedule = schedule.updateDay(updatedDay);
    
    await saveSchedule(updatedSchedule);
    return updatedDay;
  }
  
  // Update goals for a specific day
  static Future<TrainingDay> updateDayGoals(
    WeeklyTrainingSchedule schedule,
    TrainingDay day,
    String goals,
  ) async {
    final updatedDay = day.copyWith(goals: goals);
    final updatedSchedule = schedule.updateDay(updatedDay);
    
    await saveSchedule(updatedSchedule);
    return updatedDay;
  }
  
  // Update weekly goals
  static Future<WeeklyTrainingSchedule> updateWeeklyGoals(
    WeeklyTrainingSchedule schedule,
    String goals,
  ) async {
    final updatedSchedule = schedule.copyWith(weeklyGoals: goals);
    await saveSchedule(updatedSchedule);
    return updatedSchedule;
  }
} 