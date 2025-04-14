import 'package:intl/intl.dart';
import '../models/training_schedule.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class TrainingScheduleRepository {
  final ApiService apiService;

  TrainingScheduleRepository(this.apiService);

  // Get all schedules for a user
  Future<List<TrainingSchedule>> getUserSchedules(int userId) async {
    final response = await apiService.get('${ApiConfig.trainingSchedules}user/$userId/');
    return (response as List)
        .map((schedule) => TrainingSchedule.fromJson(schedule))
        .toList();
  }

  // Get a schedule by its ID
  Future<TrainingSchedule> getScheduleById(int scheduleId) async {
    final response = await apiService.get('${ApiConfig.trainingSchedules}$scheduleId/');
    return TrainingSchedule.fromJson(response);
  }

  // Get a schedule by week number and year for a specific user
  Future<TrainingSchedule?> getScheduleByWeek(int userId, int weekNumber, int year) async {
    try {
      final response = await apiService.get(
        '${ApiConfig.trainingSchedules}week?user_id=$userId&week=$weekNumber&year=$year',
      );
      return TrainingSchedule.fromJson(response);
    } catch (e) {
      // If no schedule exists for this week, return null
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  // Create a new schedule
  Future<TrainingSchedule> createSchedule(TrainingSchedule schedule) async {
    final response = await apiService.post(
      ApiConfig.trainingSchedules,
      schedule.toJson(),
    );
    return TrainingSchedule.fromJson(response);
  }

  // Update an existing schedule
  Future<TrainingSchedule> updateSchedule(int scheduleId, TrainingSchedule schedule) async {
    final response = await apiService.put(
      '${ApiConfig.trainingSchedules}$scheduleId/',
      schedule.toJson(),
    );
    return TrainingSchedule.fromJson(response);
  }

  // Delete a schedule
  Future<void> deleteSchedule(int scheduleId) async {
    await apiService.delete('${ApiConfig.trainingSchedules}$scheduleId/');
  }

  // Get all sessions for a schedule
  Future<List<TrainingSession>> getSessionsForSchedule(int scheduleId) async {
    final response = await apiService.get('${ApiConfig.trainingSchedules}$scheduleId/sessions/');
    return (response as List)
        .map((session) => TrainingSession.fromJson(session))
        .toList();
  }

  // Get a session by its ID
  Future<TrainingSession> getSessionById(int sessionId) async {
    final response = await apiService.get('${ApiConfig.trainingSessions}/$sessionId');
    return TrainingSession.fromJson(response);
  }

  // Create a new training session
  Future<TrainingSession> createSession(TrainingSession session) async {
    final response = await apiService.post(
      ApiConfig.trainingSessions,
      session.toJson(),
    );
    return TrainingSession.fromJson(response);
  }

  // Update an existing session
  Future<TrainingSession> updateSession(int sessionId, TrainingSession session) async {
    final response = await apiService.put(
      '${ApiConfig.trainingSessions}/$sessionId',
      session.toJson(),
    );
    return TrainingSession.fromJson(response);
  }

  // Delete a session
  Future<void> deleteSession(int sessionId) async {
    await apiService.delete('${ApiConfig.trainingSessions}/$sessionId');
  }

  // Add a reflection to a session
  Future<TrainingSession> addReflection(int sessionId, String reflectionText) async {
    final reflection = TrainingReflection(reflectionText: reflectionText);
    final response = await apiService.post(
      '${ApiConfig.trainingSessions}/$sessionId/reflection',
      reflection.toJson(),
    );
    return TrainingSession.fromJson(response);
  }
  
  // Helper method to calculate current week number
  int getCurrentWeekNumber() {
    final now = DateTime.now();
    // Get the first day of the year
    final firstDayOfYear = DateTime(now.year, 1, 1);
    
    // Calculate the number of days between the first day of the year and now
    final days = now.difference(firstDayOfYear).inDays;
    
    // Calculate the ISO week number
    // The formula: ((days + firstDayOfYear.weekday + 6) / 7).floor()
    // This ensures correct week calculation for any date
    return ((days + firstDayOfYear.weekday + 6) / 7).floor();
  }

  // Helper method to get dates for a specific week
  List<DateTime> getDatesForWeek(int year, int weekNumber) {
    // Calculate the first day of the year
    final firstDayOfYear = DateTime(year, 1, 1);
    
    // Calculate days to add to get to the first day of the week
    // Adjusted for ISO week (where week 1 is the week with the first Thursday)
    int daysToAdd = ((weekNumber - 1) * 7);
    if (firstDayOfYear.weekday > 4) {
      daysToAdd += (8 - firstDayOfYear.weekday);
    } else {
      daysToAdd -= (firstDayOfYear.weekday - 1);
    }
    
    // Get the Monday of the specified week
    final mondayOfWeek = firstDayOfYear.add(Duration(days: daysToAdd));
    
    // Generate all days of the week
    return List.generate(
      7, 
      (index) => mondayOfWeek.add(Duration(days: index)),
    );
  }
} 