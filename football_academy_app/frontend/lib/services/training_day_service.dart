import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/training_day.dart';
import 'api_service.dart';

class TrainingDayService {
  ApiService? _apiService;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Ensure API service is initialized
  Future<ApiService> _getApiService() async {
    if (_apiService == null) {
      _apiService = ApiService(
        client: http.Client(),
        secureStorage: _secureStorage,
      );
    }
    return _apiService!;
  }
  
  // Get all training days
  Future<List<TrainingDay>> getAllTrainingDays() async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/training-days/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TrainingDay.fromJson(json)).toList();
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error loading training days from API: $e');
      return [];
    }
  }
  
  // Get a specific training day
  Future<TrainingDay?> getTrainingDay(dynamic trainingDayId) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/training-days/$trainingDayId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TrainingDay.fromJson(data);
      } else {
        throw Exception('Failed to load training day: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading training day from API: $e');
      return null;
    }
  }
  
  // Get all entries for a user
  Future<List<TrainingDayEntry>> getUserEntries() async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/training-days/entries/user/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TrainingDayEntry.fromJson(json)).toList();
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error loading user training day entries from API: $e');
      return [];
    }
  }
  
  // Get all entries for a training day (coach only)
  Future<List<TrainingDayEntry>> getTrainingDayEntries(dynamic trainingDayId) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/training-days/entries/day/$trainingDayId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TrainingDayEntry.fromJson(json)).toList();
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error loading training day entries from API: $e');
      return [];
    }
  }
  
  // Create a new training day (coach only)
  Future<TrainingDay?> createTrainingDay(TrainingDayCreate trainingDayData) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.post(
        Uri.parse('${apiService.baseUrl}/training-days/'),
        headers: await apiService.getHeaders(),
        body: json.encode(trainingDayData.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TrainingDay.fromJson(data);
      } else {
        throw Exception('Failed to create training day: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating training day: $e');
      return null;
    }
  }
  
  // Update pre-session notes
  Future<TrainingDayEntry?> updatePreSessionNotes(dynamic entryId, String preNotes) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.put(
        Uri.parse('${apiService.baseUrl}/training-days/entries/$entryId/pre'),
        headers: await apiService.getHeaders(),
        body: json.encode({'pre_session_notes': preNotes}),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return TrainingDayEntry.fromJson(data);
      } else {
        throw Exception('Failed to update pre-session notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating pre-session notes: $e');
      return null;
    }
  }
  
  // Update post-session notes
  Future<TrainingDayEntry?> updatePostSessionNotes(dynamic entryId, String postNotes) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.put(
        Uri.parse('${apiService.baseUrl}/training-days/entries/$entryId/post'),
        headers: await apiService.getHeaders(),
        body: json.encode({'post_session_notes': postNotes}),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return TrainingDayEntry.fromJson(data);
      } else {
        throw Exception('Failed to update post-session notes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating post-session notes: $e');
      return null;
    }
  }
  
  // Update attendance status (coach only)
  Future<TrainingDayEntry?> updateAttendanceStatus(dynamic entryId, String status) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.put(
        Uri.parse('${apiService.baseUrl}/training-days/entries/$entryId/attendance'),
        headers: await apiService.getHeaders(),
        body: json.encode({'attendance_status': status}),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return TrainingDayEntry.fromJson(data);
      } else {
        throw Exception('Failed to update attendance status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating attendance status: $e');
      return null;
    }
  }
} 