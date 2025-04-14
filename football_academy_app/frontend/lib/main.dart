import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/challenge_service.dart';
import 'services/league_table_service.dart';
import 'services/navigation_service.dart';
// import 'services/development_plan_service.dart'; // Will be added back later

import 'repositories/auth_repository.dart';
import 'repositories/api_auth_repository.dart';

import 'screens/auth/login_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'screens/league_table/league_table_page.dart';
import 'screens/player_stats/player_stats_page.dart';
import 'screens/info/info_page.dart';
import 'screens/development_plan/development_plan_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/coach_dashboard/coach_dashboard_page.dart';
import 'theme/colors.dart';
import 'config/feature_flags.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final httpClient = http.Client();

  final apiService = ApiService(
    client: httpClient,
    secureStorage: secureStorage,
  );

  final authRepository = ApiAuthRepository(apiService, secureStorage);
  final authService = AuthService(
    authRepository: authRepository,
    secureStorage: secureStorage,
    apiService: apiService,
  );

  ChallengeService.initialize(apiService);
  LeagueTableService.initialize(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        Provider<FlutterSecureStorage>.value(value: secureStorage),
        Provider<http.Client>.value(value: httpClient),
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
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
      // Configure localization
      locale: const Locale('da', 'DK'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('da', 'DK'), // Danish
        Locale('en', 'US'), // English
      ],
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/development-plan': (context) => const DevelopmentPlanPage(),
        '/profile': (context) => const ProfilePage(),
        '/coach-dashboard': (context) => const CoachDashboardPage(),
        if (FeatureFlags.leagueTableEnabled)
          '/league-table': (context) => const LeagueTablePage(),
        if (FeatureFlags.playerStatsEnabled)
          '/player-stats': (context) => const PlayerStatsPage(),
        '/info': (context) => const InfoPage(),
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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0033),
              Color(0xFF2A004D),
              Color(0xFF5D006C),
              Color(0xFF9A0079),
              Color(0xFFC71585),
              Color(0xFFFF4500),
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/images/copenhagen_academy_logo.png'),
                height: 180,
              ),
              SizedBox(height: 24),
              Text(
                'Copenhagen Academy',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
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
