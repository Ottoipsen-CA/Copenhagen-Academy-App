import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/api_auth_repository.dart';
import 'navigation_service.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final AuthRepository _authRepository;
  final FlutterSecureStorage secureStorage;
  final ApiService _apiService;
  
  // Flag to use mock auth for development 
  bool _useMockAuth = false;

  AuthService({
    required AuthRepository authRepository,
    required this.secureStorage,
    required ApiService apiService,
  }) : _authRepository = authRepository,
       _apiService = apiService;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _authRepository.isLoggedIn();
  }

  // Register a new user
  Future<User> register(RegisterRequest request) async {
    if (_useMockAuth) {
      // Create mock user
      await _createMockToken();
      
      return User(
        id: 123,
        email: request.email,
        fullName: request.fullName,
        isActive: true,
        isCoach: false,
      );
    }
    
    try {
      final user = await _authRepository.registerUser(
        request.email, 
        request.fullName, 
        request.password
      );
      
      if (user != null) {
        // Login automatically after successful registration
        await _authRepository.login(request.email, request.password);
        return user;
      }
      
      // If we get here, registration failed but didn't throw an exception
      throw Exception("Registration failed: No user returned from the server");
    } catch (e) {
      print('Error during registration: $e');
      // Rethrow the error instead of falling back to mock data
      throw Exception("Registration failed: $e");
    }
  }

  // Login a user
  Future<void> login(LoginRequest request) async {
    if (_useMockAuth) {
      print('Using mock login with: ${request.email}');
      await _createMockToken();
      return;
    }
    
    try {
      final token = await _authRepository.login(request.email, request.password);
      
      if (token == null) {
        // Don't fall back to mock login
        throw Exception('Login failed: Invalid credentials or server error');
      }
    } catch (e) {
      print('Error during login: $e');
      // Don't fall back to mock login
      throw Exception('Login failed: $e');
    }
  }

  // Get current user
  Future<User> getCurrentUser() async {
    if (_useMockAuth) {
      return _createMockUser();
    }
    
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        return user;
      }
      // Don't return a mock user as fallback
      throw Exception('Failed to get current user: User data is null');
    } catch (e) {
      print('Error getting current user: $e');
      // Don't return a mock user as fallback
      throw Exception('Failed to get current user: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Clear token via repository
      await _authRepository.logout();
      
      // Also clear from secure storage directly as a backup
      await secureStorage.delete(key: 'access_token');
      
      // Clear any other potential stored auth data
      await secureStorage.delete(key: 'refresh_token');
      await secureStorage.delete(key: 'user_data');
      
      // Reset API service state
      _apiService.reset();
      
      print('Logout complete - all tokens cleared and services reset');
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      // Always reset navigation to ensure user is logged out UI-wise
      NavigationService.resetToLogin();
    }
  }

  // Get current user ID - static helper for services
  static Future<String> getCurrentUserId() async {
    // Create temporary instances to access auth repositories
    final secureStorage = FlutterSecureStorage();
    final client = http.Client();
    
    try {
      // Create API service and repository using the existing patterns
      final apiService = ApiService(client: client, secureStorage: secureStorage);
      final authRepository = ApiAuthRepository(apiService, secureStorage);
      
      // Get current user through the repository
      final user = await authRepository.getCurrentUser();
      
      if (user != null && user.id != null) {
        return user.id.toString();
      }
      
      throw Exception('Failed to get user ID from API');
    } catch (e) {
      print('Error getting user ID: $e');
      throw Exception('Failed to get user ID: $e');
    } finally {
      // Close the temporary client
      client.close();
    }
  }
  
  // Helper method to create a mock token for development
  Future<void> _createMockToken() async {
    await secureStorage.write(
      key: 'access_token',
      value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    print('Mock token saved to secure storage');
  }
  
  // Helper method to create a mock user for development
  User _createMockUser({
    String email = 'demo@example.com', 
    String fullName = 'Otto'
  }) {
    return User(
      id: 123,
      email: email,
      fullName: fullName,
      isActive: true,
      isCoach: false,
    );
  }
} 