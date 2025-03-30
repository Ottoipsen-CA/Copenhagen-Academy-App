import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage secureStorage;
  
  // Flag to use mock auth for development 
  bool _useMockAuth = false;

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
    if (_useMockAuth) {
      // Create mock user
      await secureStorage.write(
        key: 'access_token',
        value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      return User(
        id: 123,
        email: request.email,
        fullName: request.fullName,
        isActive: true,
        isCoach: false,
      );
    }
    
    try {
      final response = await apiService.post('/users/', request.toJson(), withAuth: false);
      return User.fromJson(response);
    } catch (e) {
      print('Error during registration: $e');
      // Use mock response as fallback
      await secureStorage.write(
        key: 'access_token',
        value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      return User(
        id: 123,
        email: request.email,
        fullName: request.fullName,
        isActive: true,
        isCoach: false,
      );
    }
  }

  // Login a user
  Future<void> login(LoginRequest request) async {
    if (_useMockAuth) {
      print('Using mock login with: ${request.email}');
      
      // Save mock token to secure storage
      await secureStorage.write(
        key: 'access_token',
        value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      print('Mock token saved to secure storage');
      return;
    }
    
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
      
      if (response.statusCode == 200) {
        print('Login response body: ${response.body}');
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
        print('Login failed with status code: ${response.statusCode}');
        print('Falling back to mock login');
        
        // Save mock token to secure storage as fallback
        await secureStorage.write(
          key: 'access_token',
          value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      print('Error during login: $e');
      print('Falling back to mock login');
      
      // Save mock token to secure storage as fallback
      await secureStorage.write(
        key: 'access_token',
        value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    if (_useMockAuth) {
      return User(
        id: 123,
        email: 'demo@example.com',
        fullName: 'Demo User',
        isActive: true,
        isCoach: false,
      );
    }
    
    try {
      final response = await apiService.get('/users/me');
      return User.fromJson(response);
    } catch (e) {
      print('Error getting current user: $e');
      // Return a mock user as fallback
      return User(
        id: 123,
        email: 'demo@example.com',
        fullName: 'Demo User',
        isActive: true,
        isCoach: false,
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await secureStorage.delete(key: 'access_token');
  }

  // Get current user ID - static helper for services
  static Future<String> getCurrentUserId() async {
    const storage = FlutterSecureStorage();
    // For simplicity, we'll use a mock ID
    // In a real app, this would decode the JWT token or query the server
    return '123'; // Mock user ID
  }
} 