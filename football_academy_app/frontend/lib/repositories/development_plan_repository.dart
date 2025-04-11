import 'package:flutter/foundation.dart';
import '../models/development_plan.dart';
import '../services/api_service.dart';
import 'base_repository.dart';

class DevelopmentPlanRepository implements BaseRepository<DevelopmentPlan> {
  final ApiService _apiService;

  DevelopmentPlanRepository(this._apiService);

  @override
  Future<List<DevelopmentPlan>> getAll() async {
    try {
      final response = await _apiService.get('/development-plans/user/me');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DevelopmentPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load development plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting development plans: $e');
      rethrow;
    }
  }

  @override
  Future<DevelopmentPlan?> getById(String id) async {
    try {
      final response = await _apiService.get('/development-plans/$id');
      if (response.statusCode == 200) {
        return DevelopmentPlan.fromJson(response.data);
      } else {
        throw Exception('Failed to load development plan: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting development plan: $e');
      rethrow;
    }
  }

  @override
  Future<DevelopmentPlan> create(DevelopmentPlan item) async {
    try {
      final response = await _apiService.post(
        '/development-plans/',
        data: item.toJson(),
      );
      if (response.statusCode == 201) {
        return DevelopmentPlan.fromJson(response.data);
      } else {
        throw Exception('Failed to create development plan: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating development plan: $e');
      rethrow;
    }
  }

  @override
  Future<DevelopmentPlan> update(DevelopmentPlan item) async {
    try {
      final response = await _apiService.patch(
        '/development-plans/${item.planId}',
        data: item.toJson(),
      );
      if (response.statusCode == 200) {
        return DevelopmentPlan.fromJson(response.data);
      } else {
        throw Exception('Failed to update development plan: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating development plan: $e');
      rethrow;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final response = await _apiService.delete('/development-plans/$id');
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting development plan: $e');
      rethrow;
    }
  }

  // Additional methods for weekly notes
  Future<WeeklyNote> createWeeklyNote(WeeklyNote note) async {
    try {
      final response = await _apiService.post(
        '/development-plans/${note.planId}/weekly-notes',
        data: note.toJson(),
      );
      if (response.statusCode == 201) {
        return WeeklyNote.fromJson(response.data);
      } else {
        throw Exception('Failed to create weekly note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating weekly note: $e');
      rethrow;
    }
  }

  Future<WeeklyNote> updateWeeklyNote(WeeklyNote note) async {
    try {
      final response = await _apiService.patch(
        '/development-plans/${note.planId}/weekly-notes/${note.noteId}',
        data: note.toJson(),
      );
      if (response.statusCode == 200) {
        return WeeklyNote.fromJson(response.data);
      } else {
        throw Exception('Failed to update weekly note: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating weekly note: $e');
      rethrow;
    }
  }

  Future<bool> deleteWeeklyNote(int planId, int noteId) async {
    try {
      final response = await _apiService.delete(
        '/development-plans/$planId/weekly-notes/$noteId',
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting weekly note: $e');
      rethrow;
    }
  }

  // Additional methods for match performances
  Future<MatchPerformance> createMatchPerformance(MatchPerformance performance) async {
    try {
      final response = await _apiService.post(
        '/development-plans/${performance.planId}/match-performances',
        data: performance.toJson(),
      );
      if (response.statusCode == 201) {
        return MatchPerformance.fromJson(response.data);
      } else {
        throw Exception('Failed to create match performance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating match performance: $e');
      rethrow;
    }
  }

  Future<MatchPerformance> updateMatchPerformance(MatchPerformance performance) async {
    try {
      final response = await _apiService.patch(
        '/development-plans/${performance.planId}/match-performances/${performance.performanceId}',
        data: performance.toJson(),
      );
      if (response.statusCode == 200) {
        return MatchPerformance.fromJson(response.data);
      } else {
        throw Exception('Failed to update match performance: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating match performance: $e');
      rethrow;
    }
  }

  Future<bool> deleteMatchPerformance(int planId, int performanceId) async {
    try {
      final response = await _apiService.delete(
        '/development-plans/$planId/match-performances/$performanceId',
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting match performance: $e');
      rethrow;
    }
  }

  // Method to get development plans for a specific user (for coaches)
  Future<List<DevelopmentPlan>> getUserDevelopmentPlans(int userId) async {
    try {
      final response = await _apiService.get('/development-plans/user/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DevelopmentPlan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user development plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting user development plans: $e');
      rethrow;
    }
  }

  Future<List<FocusArea>> getFocusAreas(int developmentPlanId) async {
    try {
      final response = await _apiService.get('/development-plans/$developmentPlanId/focus-areas/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => FocusArea.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load focus areas: \\${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting focus areas: $e');
      rethrow;
    }
  }
} 