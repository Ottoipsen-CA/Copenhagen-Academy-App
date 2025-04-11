import 'package:flutter/foundation.dart';
import '../models/development_plan.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'base_repository.dart';
import '../services/auth_service.dart';

class DevelopmentPlanRepository implements BaseRepository<DevelopmentPlan> {
  final ApiService _apiService;

  DevelopmentPlanRepository(this._apiService);

  // Helper method to get base endpoint without trailing slash
  String get _baseEndpoint => ApiConfig.developmentPlans.endsWith('/') 
      ? ApiConfig.developmentPlans.substring(0, ApiConfig.developmentPlans.length - 1)
      : ApiConfig.developmentPlans;

  @override
  Future<List<DevelopmentPlan>> getAll() async {
    try {
      final response = await _apiService.get('$_baseEndpoint/');
      
      if (response is List) {
        return response.map((json) => DevelopmentPlan.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> data = response['data'];
        return data.map((json) => DevelopmentPlan.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting development plans: $e');
      rethrow;
    }
  }

  @override
  Future<DevelopmentPlan?> getById(String id) async {
    try {
      final response = await _apiService.get('$_baseEndpoint/$id');
      
      return DevelopmentPlan.fromJson(response);
    } catch (e) {
      debugPrint('Error getting development plan: $e');
      rethrow;
    }
  }

  @override
  Future<DevelopmentPlan> create(DevelopmentPlan item) async {
    try {
      final response = await _apiService.post(
        '$_baseEndpoint/',
        item.toJson(),
      );
      
      return DevelopmentPlan.fromJson(response);
    } catch (e) {
      debugPrint('Error creating development plan: $e');
      rethrow;
    }
  }

  @override
  Future<DevelopmentPlan> update(DevelopmentPlan item) async {
    try {
      final endpoint = '$_baseEndpoint/${item.planId}';
      final response = await _apiService.put(
        endpoint,
        item.toJson(),
      );
      
      return DevelopmentPlan.fromJson(response);
    } catch (e) {
      debugPrint('Error updating development plan: $e');
      rethrow;
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final endpoint = '$_baseEndpoint/$id';
      await _apiService.delete(endpoint);
      return true;
    } catch (e) {
      debugPrint('Error deleting development plan: $e');
      rethrow;
    }
  }

  // Method to get development plans for the current user
  Future<List<DevelopmentPlan>> getUserPlans() async {
    try {
      // Get the current user ID
      final userId = await AuthService.getCurrentUserId();
      
      final response = await _apiService.get('$_baseEndpoint/user/$userId');
      
      if (response is List) {
        return response.map((json) => DevelopmentPlan.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> data = response['data'];
        return data.map((json) => DevelopmentPlan.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting user development plans: $e');
      rethrow;
    }
  }

  // Method to get focus areas for a specific development plan
  Future<List<FocusArea>> getFocusAreas(int developmentPlanId) async {
    try {
      final response = await _apiService.get('$_baseEndpoint/$developmentPlanId/focus-areas/');
      
      if (response is List) {
        return response.map((json) => FocusArea.fromJson(json)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List<dynamic> data = response['data'];
        return data.map((json) => FocusArea.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting focus areas: $e');
      rethrow;
    }
  }

  // Method to create a new focus area for a development plan
  Future<FocusArea> createFocusArea(FocusArea focusArea) async {
    try {
      final response = await _apiService.post(
        '$_baseEndpoint/${focusArea.developmentPlanId}/focus-areas/',
        focusArea.toJson(),
      );
      
      return FocusArea.fromJson(response);
    } catch (e) {
      debugPrint('Error creating focus area: $e');
      rethrow;
    }
  }

  // Method to update an existing focus area
  Future<FocusArea> updateFocusArea(FocusArea focusArea) async {
    try {
      final endpoint = '$_baseEndpoint/${focusArea.developmentPlanId}/focus-areas/${focusArea.focusAreaId}';
      print('Update focus area endpoint: $endpoint');
      final response = await _apiService.put(
        endpoint,
        focusArea.toJson(),
      );
      
      return FocusArea.fromJson(response);
    } catch (e) {
      debugPrint('Error updating focus area: $e');
      rethrow;
    }
  }

  // Method to update the status of a focus area
  Future<FocusArea> updateFocusAreaStatus(int developmentPlanId, int focusAreaId, String status) async {
    try {
      // Ensure consistent URL pattern
      final endpoint = '$_baseEndpoint/$developmentPlanId/focus-areas/$focusAreaId/status';
      final response = await _apiService.patch(
        endpoint,
        {'status': status},
      );
      
      return FocusArea.fromJson(response);
    } catch (e) {
      debugPrint('Error updating focus area status: $e');
      rethrow;
    }
  }

  // Method to delete a focus area
  Future<bool> deleteFocusArea(int developmentPlanId, int focusAreaId) async {
    try {
      final endpoint = '$_baseEndpoint/$developmentPlanId/focus-areas/$focusAreaId';
      print('Delete focus area endpoint: $endpoint');
      await _apiService.delete(endpoint);
      return true;
    } catch (e) {
      debugPrint('Error deleting focus area: $e');
      rethrow;
    }
  }
} 