import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage secureStorage;
  
  // Flag to use mock data when server is unavailable
  bool _useMockData = true; // Set to true for development

  ApiService({
    required this.client,
    required this.secureStorage,
  }) {
    // Use localhost for development
    baseUrl = 'http://localhost:8080';
    
    // In production, use the actual API URL
    // baseUrl = 'https://api.footballacademy.dev/v1';
  }

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add CORS headers for web
    if (kIsWeb) {
      headers['Access-Control-Allow-Origin'] = '*';
      headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
      headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, X-Auth-Token';
    }

    if (withAuth) {
      final token = await secureStorage.read(key: 'access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Generic GET request
  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    if (_useMockData) {
      return _getMockData(endpoint);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      print('GET request to: $baseUrl$endpoint');
      
      final response = await client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      print('GET response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('GET request failed with status: ${response.statusCode}');
        // Fall back to mock data if server request fails
        return _getMockData(endpoint);
      }
    } catch (e) {
      print('Error in GET request: $e');
      // Fall back to mock data if server request fails
      return _getMockData(endpoint);
    }
  }

  // Generic POST request
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    if (_useMockData) {
      return _getMockDataForPost(endpoint, data);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      print('POST Request to: $baseUrl$endpoint');
      print('Headers: $headers');
      print('Body: ${json.encode(data)}');
      
      // For web, try sending a preflight OPTIONS request first
      if (kIsWeb) {
        print('Web platform detected - CORS preflight may be needed');
        // The http package doesn't have an options method
        // We'll handle CORS on the server side
      }
      
      final response = await client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return json.decode(response.body);
      } else {
        print('POST request failed with status: ${response.statusCode}');
        // Fall back to mock data if server request fails
        return _getMockDataForPost(endpoint, data);
      }
    } catch (e) {
      print('Error in POST request: $e');
      // Fall back to mock data if server request fails
      return _getMockDataForPost(endpoint, data);
    }
  }

  // Generic PUT request
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    if (_useMockData) {
      return _getMockDataForPut(endpoint, data);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        print('PUT request failed with status: ${response.statusCode}');
        // Fall back to mock data if server request fails
        return _getMockDataForPut(endpoint, data);
      }
    } catch (e) {
      print('Error in PUT request: $e');
      // Fall back to mock data if server request fails
      return _getMockDataForPut(endpoint, data);
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    if (_useMockData) {
      return _getMockDataForDelete(endpoint);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return json.decode(response.body);
      } else {
        print('DELETE request failed with status: ${response.statusCode}');
        // Fall back to mock data if server request fails
        return _getMockDataForDelete(endpoint);
      }
    } catch (e) {
      print('Error in DELETE request: $e');
      // Fall back to mock data if server request fails
      return _getMockDataForDelete(endpoint);
    }
  }
  
  // Provide mock data for development
  dynamic _getMockData(String endpoint) {
    print('Using mock data for GET: $endpoint');
    
    if (endpoint == '/users/me') {
      return {
        'id': 123,
        'email': 'demo@example.com',
        'full_name': 'Otto',
        'position': 'Forward',
        'current_club': 'Copenhagen Academy',
        'date_of_birth': '2000-01-01T00:00:00Z',
        'is_active': true,
        'is_coach': false,
      };
    }
    
    if (endpoint.contains('/challenges')) {
      return _getMockChallenges();
    }
    
    return {};
  }
  
  dynamic _getMockDataForPost(String endpoint, Map<String, dynamic> data) {
    print('Using mock data for POST: $endpoint');
    
    if (endpoint.contains('/challenges')) {
      return {
        'id': '999',
        'title': data['title'] ?? 'New Challenge',
        'description': data['description'] ?? 'Challenge description',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'active',
      };
    }
    
    return {};
  }
  
  dynamic _getMockDataForPut(String endpoint, Map<String, dynamic> data) {
    print('Using mock data for PUT: $endpoint');
    return data;
  }
  
  dynamic _getMockDataForDelete(String endpoint) {
    print('Using mock data for DELETE: $endpoint');
    return null;
  }
  
  List<Map<String, dynamic>> _getMockChallenges() {
    return [
      {
        'id': '1',
        'title': 'Run 5km',
        'description': 'Complete a 5km run',
        'points': 100,
        'status': 'active',
        'created_at': '2023-01-01T00:00:00Z',
      },
      {
        'id': '2',
        'title': 'Score 10 goals',
        'description': 'Score 10 goals in training',
        'points': 200,
        'status': 'active',
        'created_at': '2023-01-02T00:00:00Z',
      },
      {
        'id': '3',
        'title': 'Assist 5 times',
        'description': 'Make 5 assists in matches',
        'points': 150,
        'status': 'active',
        'created_at': '2023-01-03T00:00:00Z',
      },
    ];
  }
} 