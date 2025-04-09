import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/development_plan.dart';
import '../config/api_config.dart';

class DevelopmentPlanService {
  final http.Client _client;
  DevelopmentPlan? _currentPlan;
  
  // Flag to use mock data when server is unavailable
  bool _useMockData = true; // Set to true for development

  DevelopmentPlanService({http.Client? client}) : _client = client ?? http.Client();

  DevelopmentPlan? get currentPlan => _currentPlan;

  Future<List<DevelopmentPlan>> getDevelopmentPlans() async {
    if (_useMockData) {
      print('Using mock data for development plans');
      return _getMockDevelopmentPlans();
    }
    
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/development-plans'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final plans = data.map((json) => DevelopmentPlan.fromJson(json)).toList();
        if (plans.isNotEmpty) {
          _currentPlan = plans.first;
        }
        return plans;
      } else {
        throw Exception('Failed to load development plans');
      }
    } catch (e) {
      print('Error getting development plans: $e');
      rethrow;
    }
  }

  // Mock data for development
  List<DevelopmentPlan> _getMockDevelopmentPlans() {
    // Create a sample development plan with training sessions
    final List<TrainingSession> sessions = [
      TrainingSession(
        sessionId: 1,
        planId: 1,
        title: 'Technical Training',
        description: 'Focus on ball control and passing',
        date: DateTime.now(),
        weekday: 1, // Monday
        startTime: '16:00',
        durationMinutes: 90,
        preEvaluation: null,
        postEvaluation: null,
        isCompleted: false,
      ),
      TrainingSession(
        sessionId: 2,
        planId: 1,
        title: 'Tactical Training',
        description: 'Team formation and positioning',
        date: DateTime.now().add(const Duration(days: 2)),
        weekday: 3, // Wednesday
        startTime: '17:30',
        durationMinutes: 120,
        preEvaluation: null,
        postEvaluation: null,
        isCompleted: false,
      ),
      TrainingSession(
        sessionId: 3,
        planId: 1,
        title: 'Match',
        description: 'Friendly match against local team',
        date: DateTime.now().add(const Duration(days: 5)),
        weekday: 5, // Friday
        startTime: '19:00',
        durationMinutes: 90,
        preEvaluation: null,
        postEvaluation: null,
        isCompleted: false,
      ),
    ];
    
    // Create focus areas for the player's development
    final List<FocusArea> focusAreas = [
      FocusArea(
        id: 1,
        title: 'Ball Control',
        description: 'Improve first touch and close ball control in tight spaces',
        priority: 5,
        targetDate: DateTime.now().add(const Duration(days: 60)),
        isCompleted: false,
      ),
      FocusArea(
        id: 2,
        title: 'Passing Accuracy',
        description: 'Develop consistent passing over various distances',
        priority: 4,
        targetDate: DateTime.now().add(const Duration(days: 45)),
        isCompleted: false,
      ),
      FocusArea(
        id: 3,
        title: 'Positional Awareness',
        description: 'Better understanding of team formation and movement',
        priority: 3,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        isCompleted: false,
      ),
      FocusArea(
        id: 4,
        title: 'Shooting Power',
        description: 'Increase shot power while maintaining accuracy',
        priority: 4,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        isCompleted: false,
      ),
    ];
    
    final plan = DevelopmentPlan(
      id: 1,
      playerId: 1,
      title: 'My Training Plan',
      trainingSessions: sessions,
      focusAreas: focusAreas,
      longTermGoals: 'Develop into a complete midfielder with strong technical and tactical abilities',
      notes: 'Focus on consistency in training attendance and effort',
    );
    
    _currentPlan = plan;
    return [plan];
  }

  Future<DevelopmentPlan> createDevelopmentPlan(DevelopmentPlan plan) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/development-plans'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(plan.toJson()),
      );

      if (response.statusCode == 201) {
        final createdPlan = DevelopmentPlan.fromJson(json.decode(response.body));
        _currentPlan = createdPlan;
        return createdPlan;
      } else {
        throw Exception('Failed to create development plan');
      }
    } catch (e) {
      print('Error creating development plan: $e');
      rethrow;
    }
  }

  Future<DevelopmentPlan> updateDevelopmentPlan(DevelopmentPlan plan) async {
    try {
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/development-plans/${plan.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(plan.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedPlan = DevelopmentPlan.fromJson(json.decode(response.body));
        _currentPlan = updatedPlan;
        return updatedPlan;
      } else {
        throw Exception('Failed to update development plan');
      }
    } catch (e) {
      print('Error updating development plan: $e');
      rethrow;
    }
  }

  Future<void> deleteDevelopmentPlan(int planId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/development-plans/$planId'),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete development plan');
      }

      if (_currentPlan?.id == planId) {
        _currentPlan = null;
      }
    } catch (e) {
      print('Error deleting development plan: $e');
      rethrow;
    }
  }

  Future<TrainingSession> addTrainingSession(TrainingSession session) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/training-sessions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(session.toJson()),
      );

      if (response.statusCode == 201) {
        final createdSession = TrainingSession.fromJson(json.decode(response.body));
        if (_currentPlan != null) {
          _currentPlan!.trainingSessions.add(createdSession);
        }
        return createdSession;
      } else {
        throw Exception('Failed to add training session');
      }
    } catch (e) {
      print('Error adding training session: $e');
      rethrow;
    }
  }

  Future<TrainingSession> updateTrainingSession(TrainingSession session) async {
    try {
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/training-sessions/${session.sessionId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(session.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedSession = TrainingSession.fromJson(json.decode(response.body));
        if (_currentPlan != null) {
          final index = _currentPlan!.trainingSessions
              .indexWhere((s) => s.sessionId == session.sessionId);
          if (index != -1) {
            _currentPlan!.trainingSessions[index] = updatedSession;
          }
        }
        return updatedSession;
      } else {
        throw Exception('Failed to update training session');
      }
    } catch (e) {
      print('Error updating training session: $e');
      rethrow;
    }
  }

  Future<SessionEvaluation> addSessionEvaluation(
    String sessionId,
    SessionEvaluation evaluation,
    bool isPre,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/training-sessions/$sessionId/evaluations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...evaluation.toJson(),
          'is_pre': isPre,
        }),
      );

      if (response.statusCode == 201) {
        return SessionEvaluation.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add evaluation');
      }
    } catch (e) {
      print('Error adding evaluation: $e');
      rethrow;
    }
  }

  Future<void> deleteSessionEvaluation(String sessionId, String evaluationId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v2/training-sessions/$sessionId/evaluations/$evaluationId'),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete evaluation');
      }
    } catch (e) {
      print('Error deleting evaluation: $e');
      rethrow;
    }
  }
} 