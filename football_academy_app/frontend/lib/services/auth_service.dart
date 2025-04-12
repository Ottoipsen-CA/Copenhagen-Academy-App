import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/api_auth_repository.dart';
import 'navigation_service.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final AuthRepository _authRepository;
  final FlutterSecureStorage secureStorage;
  final ApiService _apiService;

  bool _useMockAuth = false;

  AuthService({
    required AuthRepository authRepository,
    required this.secureStorage,
    required ApiService apiService,
  })  : _authRepository = authRepository,
        _apiService = apiService;

  Future<bool> isLoggedIn() async {
    final token = await secureStorage.read(key: 'access_token');
    return token != null;
  }

  Future<User> register(RegisterRequest request) async {
    if (_useMockAuth) {
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
        request.password,
      );

      if (user != null) {
        final token = await _authRepository.login(request.email, request.password);

        if (token != null) {
          await secureStorage.write(key: 'access_token', value: token);
          return user;
        }
      }

      throw Exception("Registration failed: No user or token returned");
    } catch (e) {
      print('Error during registration: $e');
      throw Exception("Registration failed: $e");
    }
  }

  Future<void> login(LoginRequest request) async {
    if (_useMockAuth) {
      print('Using mock login with: ${request.email}');
      await _createMockToken();
      return;
    }

    try {
      final token = await _authRepository.login(request.email, request.password);

      if (token == null) {
        throw Exception('Login failed: Invalid credentials or server error');
      }

      // 🔐 Gem token i secure storage
      await secureStorage.write(key: 'access_token', value: token);
      print('Token gemt i secure storage!');
    } catch (e) {
      print('Error during login: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<User> getCurrentUser() async {
    if (_useMockAuth) {
      return _createMockUser();
    }

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        return user;
      }

      throw Exception('Failed to get current user: User is null');
    } catch (e) {
      print('Error getting current user: $e');
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();

      await secureStorage.delete(key: 'access_token');
      await secureStorage.delete(key: 'refresh_token');
      await secureStorage.delete(key: 'user_data');

      _apiService.reset();

      print('Logout complete - tokens cleared and services reset');
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      NavigationService.resetToLogin();
    }
  }

  static Future<String> getCurrentUserId() async {
    final secureStorage = FlutterSecureStorage();
    final client = http.Client();

    try {
      final apiService = ApiService(client: client, secureStorage: secureStorage);
      final authRepository = ApiAuthRepository(apiService, secureStorage);

      final user = await authRepository.getCurrentUser();

      if (user != null && user.id != null) {
        return user.id.toString();
      }

      throw Exception('Failed to get user ID from API');
    } catch (e) {
      print('Error getting user ID: $e');
      throw Exception('Failed to get user ID: $e');
    } finally {
      client.close();
    }
  }

  Future<void> _createMockToken() async {
    await secureStorage.write(
      key: 'access_token',
      value: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    );
    print('Mock token saved to secure storage');
  }

  User _createMockUser({
    String email = 'demo@example.com',
    String fullName = 'Otto',
  }) {
    return User(
      id: 123,
      email: email,
      fullName: fullName,
      isActive: true,
      isCoach: false,
    );
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _apiService.get('/api/v2/auth/me');
      return response;
    } catch (e) {
      // If we can't get the user info, return a default ID of 1
      return {'id': 1};
    }
  }

  Future<String?> getToken() async {
    return await secureStorage.read(key: 'access_token');
  }
}
