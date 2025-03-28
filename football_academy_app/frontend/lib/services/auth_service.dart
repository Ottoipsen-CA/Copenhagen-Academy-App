import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage secureStorage;

  AuthService({
    required this.apiService,
    required this.secureStorage,
  });

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await secureStorage.read(key: 'access_token');
    return token != null;
  }

  // Register a new user
  Future<User> register(RegisterRequest request) async {
    final response = await apiService.post('/users/', request.toJson(), withAuth: false);
    return User.fromJson(response);
  }

  // Login a user
  Future<void> login(LoginRequest request) async {
    // FastAPI uses form data for OAuth token endpoint
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final data = {
      'username': request.email,
      'password': request.password,
      'grant_type': 'password',
    };

    // Convert map to URL encoded form data
    final formData = data.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final uri = Uri.parse('${apiService.baseUrl}/token');
    print('Login request to: $uri');
    print('Login request headers: $headers');
    print('Login request body: $formData');
    
    try {
      final response = await apiService.client.post(
        uri,
        headers: headers,
        body: formData,
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(
          jsonDecode(response.body),
        );

        // Save token to secure storage
        await secureStorage.write(
          key: 'access_token',
          value: authResponse.accessToken,
        );
        print('Token saved to secure storage');
      } else {
        throw Exception('Login failed: [${response.statusCode}] ${response.body}');
      }
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    final response = await apiService.get('/users/me');
    return User.fromJson(response);
  }

  // Logout
  Future<void> logout() async {
    await secureStorage.delete(key: 'access_token');
  }
} 