import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/challenge_service.dart';
import '../models/challenge.dart';

class ApiConnectionTest extends StatefulWidget {
  const ApiConnectionTest({Key? key}) : super(key: key);

  @override
  _ApiConnectionTestState createState() => _ApiConnectionTestState();
}

class _ApiConnectionTestState extends State<ApiConnectionTest> {
  final ApiService _apiService = ApiService(
    client: http.Client(),
    secureStorage: const FlutterSecureStorage(),
  );
  
  final AuthService _authService = AuthService();
  final ChallengeService _challengeService = ChallengeService();
  
  String _result = "No test run yet";
  bool _isLoading = false;

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _result = "Testing API connection...";
    });

    try {
      // Test basic API connection
      final response = await _apiService.get('/health-check');
      
      final statusMessage = response.statusCode == 200 
          ? "API connection successful!" 
          : "API connection failed with status: ${response.statusCode}";
      
      setState(() {
        _result = statusMessage;
      });
    } catch (e) {
      setState(() {
        _result = "API connection error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthService() async {
    setState(() {
      _isLoading = true;
      _result = "Testing AuthService...";
    });

    try {
      // Test login
      final loginSuccess = await _authService.login(
        'player@example.com', 
        'password123'
      );

      final user = await _authService.getCurrentUser();

      setState(() {
        _result = loginSuccess 
            ? "Login successful! User: ${user?.fullName}" 
            : "Login failed";
      });
    } catch (e) {
      setState(() {
        _result = "AuthService error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testChallengeService() async {
    setState(() {
      _isLoading = true;
      _result = "Testing ChallengeService...";
    });

    try {
      // Get all challenges
      final challenges = await _challengeService.getAllChallenges();

      setState(() {
        _result = "Retrieved ${challenges.length} challenges";
        if (challenges.isNotEmpty) {
          _result += "\nFirst challenge: ${challenges.first.title}";
        }
      });
    } catch (e) {
      setState(() {
        _result = "ChallengeService error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connection Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  _result,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _testApiConnection,
                child: const Text('Test API Connection'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _testAuthService,
                child: const Text('Test Auth Service'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _testChallengeService,
                child: const Text('Test Challenge Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 