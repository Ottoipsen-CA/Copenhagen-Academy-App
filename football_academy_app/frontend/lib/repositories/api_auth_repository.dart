import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;
  
  ApiAuthRepository(this._apiService, this._secureStorage);
  
  @override
  Future<String?> login(String email, String password) async {
    try {
      // FastAPI uses form data for OAuth token endpoint
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final data = {
        'username': email,
        'password': password,
        'grant_type': 'password',
      };

      // Convert map to URL encoded form data
      final formData = data.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final uri = Uri.parse('${_apiService.baseUrl}${ApiConfig.login}');
      
      final response = await _apiService.client.post(
        uri,
        headers: headers,
        body: formData,
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(
          jsonDecode(response.body),
        );

        // Save token to secure storage
        await _secureStorage.write(
          key: 'access_token',
          value: authResponse.accessToken,
        );
        
        return authResponse.accessToken;
      }
      
      return null;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }
  
  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
  }
  
  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null;
  }
  
  @override
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiConfig.userProfile);
      return User.fromJson(response);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  @override
  Future<User?> registerUser(String email, String fullName, String password) async {
    try {
      final userData = {
        'email': email,
        'full_name': fullName,
        'password': password,
      };
      
      print('Registering user with data: $userData');
      print('POST request to: ${_apiService.baseUrl}${ApiConfig.register}');
      
      final response = await _apiService.post(ApiConfig.register, userData, withAuth: false);
      
      if (response == null) {
        print('Registration failed: No response from server');
        return null;
      }
      
      print('Registration response: $response');
      return User.fromJson(response);
    } catch (e) {
      print('Error registering user: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  @override
  Future<User?> updateUser(User user) async {
    try {
      final userData = user.toJson();
      // Remove id and other fields that shouldn't be sent for update
      userData.remove('id');
      
      final response = await _apiService.put(ApiConfig.userProfile, userData);
      return User.fromJson(response);
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }
} 