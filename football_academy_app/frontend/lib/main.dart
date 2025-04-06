import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/challenge_service.dart';
import 'services/navigation_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/api_auth_repository.dart';
import 'screens/auth/login_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/exercises/exercises_page.dart';
import 'screens/training_schedule/training_schedule_page.dart';
import 'screens/challenges/challenges_page.dart';
import 'screens/league_table/league_table_page.dart';
import 'screens/player_stats/player_stats_page.dart';
import 'screens/info/info_page.dart';
import 'screens/splash_screen.dart';
import 'config/feature_flags.dart';

// Conditionally import training plans only if enabled
// This ensures the training plan pages won't be compiled if disabled
// import 'screens/training_plans/training_plan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize secure storage
  const secureStorage = FlutterSecureStorage();
  
  // Initialize HTTP client
  final httpClient = http.Client();
  
  // Initialize API service
  final apiService = ApiService(
    client: httpClient,
    secureStorage: secureStorage,
  );
  
  // Initialize repositories
  final authRepository = ApiAuthRepository(
    apiService,
    secureStorage,
  );
  
  // Initialize auth service with repository
  final authService = AuthService(
    authRepository: authRepository,
    secureStorage: secureStorage,
    apiService: apiService,
  );
  
  // Initialize challenge service
  ChallengeService.initialize(apiService);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        Provider<FlutterSecureStorage>.value(value: secureStorage),
        Provider<http.Client>.value(value: httpClient),
        Provider<ApiService>.value(value: apiService),
        
        // Provide repositories
        Provider<AuthRepository>.value(value: authRepository),
        
        // Provide services
        Provider<AuthService>.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Copenhagen Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A2E)),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        if (FeatureFlags.exercisesEnabled)
          '/exercises': (context) => const ExercisesPage(),
        if (FeatureFlags.challengesEnabled)
          '/challenges': (context) => const ChallengesPage(),
        '/training-schedule': (context) => const TrainingSchedulePage(),
        if (FeatureFlags.leagueTableEnabled)
          '/league-table': (context) => const LeagueTablePage(),
        if (FeatureFlags.playerStatsEnabled)
          '/player-stats': (context) => const PlayerStatsPage(),
        '/info': (context) => const InfoPage(),
        
        // Training plans route is completely disabled via feature flag
        // if (FeatureFlags.trainingPlanEnabled)
        //   '/training-plans': (context) => const TrainingPlanPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Display splash for 2 seconds
    
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark purple
              Color(0xFF3D007A), // Medium purple
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Copenhagen Academy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Træn og bliv spillets legende',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 