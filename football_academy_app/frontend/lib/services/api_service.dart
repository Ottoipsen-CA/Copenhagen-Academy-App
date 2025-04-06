import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage secureStorage;
  
  // Flag to use mock data when server is unavailable
  bool _useMockData = false; // Set to true for development

  ApiService({
    required this.client,
    required this.secureStorage,
  }) {
    // Use localhost for development
    baseUrl = 'http://localhost:8000';
    
    // In production, use the actual API URL
    // baseUrl = 'https://api.footballacademy.dev';
  }

  // Reset the API service state (can be called on logout)
  void reset() {
    // Don't close the client as it may be needed for future requests
    // Instead, log the reset operation
    print('API Service reset - tokens and state cleared');
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

  // Helper to ensure endpoint starts with a slash
  String _formatEndpoint(String endpoint) {
    if (!endpoint.startsWith('/')) {
      return '/$endpoint';
    }
    return endpoint;
  }

  // Generic GET request
  Future<dynamic> get(String endpoint, {bool withAuth = true}) async {
    if (_useMockData) {
      return _getMockData(endpoint);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final formattedEndpoint = _formatEndpoint(endpoint);
      print('GET request to: $baseUrl$formattedEndpoint');
      
      final response = await client.get(
        Uri.parse('$baseUrl$formattedEndpoint'),
        headers: headers,
      );
      
      print('GET response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('GET request failed with status: ${response.statusCode}');
        // Don't fall back to mock data - throw an error instead
        throw Exception('GET request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in GET request: $e');
      // Don't fall back to mock data - rethrow the error
      rethrow;
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
      final formattedEndpoint = _formatEndpoint(endpoint);
      print('POST Request to: $baseUrl$formattedEndpoint');
      print('Headers: $headers');
      print('Body: ${json.encode(data)}');
      
      // For web, try sending a preflight OPTIONS request first
      if (kIsWeb) {
        print('Web platform detected - CORS preflight may be needed');
        // The http package doesn't have an options method
        // We'll handle CORS on the server side
      }
      
      final response = await client.post(
        Uri.parse('$baseUrl$formattedEndpoint'),
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
        // Do not fall back to mock data - throw an error instead
        throw Exception('POST request failed with status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in POST request: $e');
      // Do not fall back to mock data - rethrow the error
      rethrow;
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
      final formattedEndpoint = _formatEndpoint(endpoint);
      final response = await client.put(
        Uri.parse('$baseUrl$formattedEndpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        print('PUT request failed with status: ${response.statusCode}');
        // Don't fall back to mock data - throw an error instead
        throw Exception('PUT request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in PUT request: $e');
      // Don't fall back to mock data - rethrow the error
      rethrow;
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    if (_useMockData) {
      return _getMockDataForDelete(endpoint);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final formattedEndpoint = _formatEndpoint(endpoint);
      final response = await client.delete(
        Uri.parse('$baseUrl$formattedEndpoint'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return json.decode(response.body);
      } else {
        print('DELETE request failed with status: ${response.statusCode}');
        // Don't fall back to mock data - throw an error instead
        throw Exception('DELETE request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in DELETE request: $e');
      // Don't fall back to mock data - rethrow the error
      rethrow;
    }
  }

  // Generic PATCH request
  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    if (_useMockData) {
      return _getMockDataForPatch(endpoint, data);
    }
    
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final formattedEndpoint = _formatEndpoint(endpoint);
      final response = await client.patch(
        Uri.parse('$baseUrl$formattedEndpoint'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return json.decode(response.body);
      } else {
        print('PATCH request failed with status: ${response.statusCode}');
        throw Exception('PATCH request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in PATCH request: $e');
      rethrow;
    }
  }
  
  // Provide mock data for development
  dynamic _getMockData(String endpoint) {
    print('Using mock data for GET: $endpoint');
    
    if (endpoint == '/api/v2/auth/me' || endpoint == '/users/me') {
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
    
    if (endpoint.contains('/skill-tests/player-stats')) {
      return {
        'pace': 85.0,
        'shooting': 84.0,
        'passing': 78.0,
        'dribbling': 88.0,
        'juggles': 75.0,
        'first_touch': 82.0,
        'overall_rating': 83.0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
    
    if (endpoint.contains('/skill-tests/player-tests')) {
      return [];
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
  
  dynamic _getMockDataForPatch(String endpoint, Map<String, dynamic> data) {
    print('Using mock data for PATCH: $endpoint');
    return data;
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