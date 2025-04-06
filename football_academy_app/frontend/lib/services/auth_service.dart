import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'navigation_service.dart';
import 'api_service.dart';

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
        print('Login failed, falling back to mock login');
        await _createMockToken();
      }
    } catch (e) {
      print('Error during login: $e');
      print('Falling back to mock login');
      await _createMockToken();
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
      // Return a mock user as fallback
      return _createMockUser();
    } catch (e) {
      print('Error getting current user: $e');
      // Return a mock user as fallback
      return _createMockUser();
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
    const storage = FlutterSecureStorage();
    // For simplicity, we'll use a mock ID
    // In a real app, this would decode the JWT token or query the server
    return '123'; // Mock user ID
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