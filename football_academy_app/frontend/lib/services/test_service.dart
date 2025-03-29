import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/test.dart';
import 'api_service.dart';

class TestService {
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
  
  // Get all tests
  Future<List<Test>> getAllTests() async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/tests/');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Test.fromJson(json)).toList();
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error loading tests from API: $e');
      return [];
    }
  }
  
  // Get a specific test
  Future<Test?> getTest(dynamic testId) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/tests/$testId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Test.fromJson(data);
      } else {
        throw Exception('Failed to load test: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading test from API: $e');
      return null;
    }
  }
  
  // Get all test entries for a user
  Future<List<TestEntry>> getUserTestEntries(dynamic userId) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/tests/entries/user/$userId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TestEntry.fromJson(json)).toList();
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error loading user test entries from API: $e');
      return [];
    }
  }
  
  // Get all test entries for a specific test (coach only)
  Future<List<TestEntry>> getTestEntries(dynamic testId) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get('/tests/entries/test/$testId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TestEntry.fromJson(json)).toList();
      } else {
        print('Unexpected response: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error loading test entries from API: $e');
      return [];
    }
  }
  
  // Create a new test (coach only)
  Future<Test?> createTest(TestCreate testData) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.post(
        Uri.parse('${apiService.baseUrl}/tests/'),
        headers: await apiService.getHeaders(),
        body: json.encode(testData.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Test.fromJson(data);
      } else {
        throw Exception('Failed to create test: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating test: $e');
      return null;
    }
  }
  
  // Create a test entry (coach only)
  Future<TestEntry?> createTestEntry(TestEntryCreate entryData) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.post(
        Uri.parse('${apiService.baseUrl}/tests/entries/'),
        headers: await apiService.getHeaders(),
        body: json.encode(entryData.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TestEntry.fromJson(data);
      } else {
        throw Exception('Failed to create test entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating test entry: $e');
      return null;
    }
  }
  
  // Update a test entry (coach only)
  Future<TestEntry?> updateTestEntry(dynamic entryId, TestEntryCreate entryData) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.put(
        Uri.parse('${apiService.baseUrl}/tests/entries/$entryId'),
        headers: await apiService.getHeaders(),
        body: json.encode(entryData.toJson()),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return TestEntry.fromJson(data);
      } else {
        throw Exception('Failed to update test entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating test entry: $e');
      return null;
    }
  }
  
  // Delete a test entry (coach only)
  Future<bool> deleteTestEntry(dynamic entryId) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.client.delete(
        Uri.parse('${apiService.baseUrl}/tests/entries/$entryId'),
        headers: await apiService.getHeaders(),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting test entry: $e');
      return false;
    }
  }
} 