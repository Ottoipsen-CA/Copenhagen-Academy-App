import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage secureStorage;

  ApiService({
    required this.client,
    required this.secureStorage,
  }) {
    // Use localhost for web, 10.0.2.2 for Android emulator
    baseUrl = kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';
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
    final headers = await _getHeaders(withAuth: withAuth);
    final response = await client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to perform GET request: ${response.body}');
    }
  }

  // Generic POST request
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    final headers = await _getHeaders(withAuth: withAuth);
    print('POST Request to: $baseUrl$endpoint');
    print('Headers: $headers');
    print('Body: ${json.encode(data)}');
    
    try {
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
        throw Exception('Failed to perform POST request: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      print('Error in POST request: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    final headers = await _getHeaders(withAuth: withAuth);
    final response = await client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to perform PUT request: ${response.body}');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    final headers = await _getHeaders(withAuth: withAuth);
    final response = await client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw Exception('Failed to perform DELETE request: ${response.body}');
    }
  }
} 