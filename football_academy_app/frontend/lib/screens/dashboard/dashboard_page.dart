import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/player_stats.dart';
import '../../models/challenge.dart';
import '../../models/badge.dart';
import '../../models/player_test.dart';
import '../../models/development_plan.dart';
import '../../services/auth_service.dart';
import '../../services/player_stats_service.dart';
import '../../services/challenge_service.dart';
import '../../services/player_tests_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/player_stats_radar_chart.dart';
import '../../widgets/fifa_player_card.dart';
import '../../widgets/skill_progress_bar.dart';
import '../../widgets/player_test_widget.dart';
import '../../config/feature_flags.dart';
import 'dart:math' as math;
import '../../services/development_plan_service.dart';

// Import main feature flag
import '../../main.dart';

// Import pages
import '../badges/badges_page.dart';
import '../challenges/challenges_page.dart';
import '../player_tests/player_tests_page.dart';
import 'dart:io'; // For File

// Temporary class for dashboard display until backend integration
class TrainingSession {
  final int weekday;
  final String? startTime;
  final String title;
  final bool isCompleted;

  TrainingSession({
    required this.weekday,
    this.startTime,
    required this.title,
    this.isCompleted = false,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? _user;
  PlayerStats? _playerStats;
  Challenge? _weeklyChallenge;
  UserChallenge? _userWeeklyChallenge;
  List<UserBadge> _badges = [];
  DevelopmentPlan? _developmentPlan;
  bool _isLoading = true;
  String? _errorMessage;
  int _xpProgress = 440;
  int _xpTarget = 1200;
  bool _hasRecordBreakingScores = false;
  DevelopmentPlanService _developmentPlanService = DevelopmentPlanService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Load user data
      final user = await authService.getCurrentUser();
      
      // Set up player test service
      PlayerTestsService.initialize(context);
      
      // Load player stats from the latest test
      List<PlayerTest> tests = [];
      try {
        tests = await PlayerTestsService.getPlayerTests(context);
        tests.sort((a, b) {
          if (a.testDate == null) return 1;
          if (b.testDate == null) return -1;
          return b.testDate!.compareTo(a.testDate!);
        });
      } catch (e) {
        print('Error loading test data: $e');
      }
      
      // Create player stats from latest test or use default values if no tests
      PlayerStats playerStats;
      if (tests.isNotEmpty) {
        // Convert the latest test to PlayerStats
        final latestTest = tests.first;
        playerStats = PlayerStats(
          pace: (latestTest.paceRating ?? 50).toDouble(),
          shooting: (latestTest.shootingRating ?? 50).toDouble(),
          passing: (latestTest.passingRating ?? 50).toDouble(),
          dribbling: (latestTest.dribblingRating ?? 50).toDouble(),
          juggles: (latestTest.jugglesRating ?? 50).toDouble(),
          firstTouch: (latestTest.firstTouchRating ?? 50).toDouble(),
          overallRating: latestTest.overallRating != null ? latestTest.overallRating!.toDouble() : null,
          lastUpdated: latestTest.testDate,
          lastTestId: latestTest.id,
        );
        
        // Check if player has any record-breaking scores
        _hasRecordBreakingScores = latestTest.isPassingRecord == true || 
                                latestTest.isSprintRecord == true || 
                                latestTest.isFirstTouchRecord == true || 
                                latestTest.isShootingRecord == true || 
                                latestTest.isJugglingRecord == true || 
                                latestTest.isDribblingRecord == true;
      } else {
        // Create default stats if no tests are available
        playerStats = PlayerStats(
          pace: 50.0,
          shooting: 50.0,
          passing: 50.0,
          dribbling: 50.0,
          juggles: 50.0,
          firstTouch: 50.0,
          overallRating: 50.0,
          lastUpdated: DateTime.now(),
        );
      }
      
      // Load Development Plan
      DevelopmentPlan? loadedPlan;
      try {
        final plans = await _developmentPlanService.getDevelopmentPlans();
        if (plans.isNotEmpty) {
          loadedPlan = plans.first; // Assuming we only care about the first/primary plan
        }
      } catch (e) {
        print('Error loading development plan for dashboard: $e');
        // Don't necessarily fail the whole dashboard load, maybe show a message in the section
      }
      
      // Initialize challenges
      await ChallengeService.initializeUserChallenges();
      
      // Load active challenge - might be null if no challenges available
      final weeklyChallenge = await ChallengeService.getWeeklyChallenge();
      
      // Load user challenge status
      UserChallenge? userWeeklyChallenge;
      if (weeklyChallenge != null) {
        try {
          // Try getting all user challenges and find the one matching our weekly challenge
          final userChallenges = await ChallengeService.getUserChallenges();
          userWeeklyChallenge = userChallenges.firstWhere(
            (uc) => uc.challengeId == weeklyChallenge.id,
            orElse: () {
              // If not found in user challenges, check if challenge has status info
              if (weeklyChallenge.status != ChallengeStatus.locked && 
                  weeklyChallenge.status != ChallengeStatus.available) {
                // Create from challenge status if it's not locked/available
                return UserChallenge(
                  challengeId: weeklyChallenge.id,
                  status: weeklyChallenge.status,
                  startedAt: weeklyChallenge.optedInAt ?? DateTime.now(),
                  completedAt: weeklyChallenge.completedAt,
                  currentValue: weeklyChallenge.userValue?.toInt() ?? 0,
                );
              }
              // Otherwise, return as available
              return UserChallenge(
                challengeId: weeklyChallenge.id,
                status: ChallengeStatus.available,
                startedAt: DateTime.now(),
              );
            },
          );
        } catch (e) {
          print('Error getting user challenge status: $e');
          // Create a default user challenge if not found or on error
          userWeeklyChallenge = UserChallenge(
            challengeId: weeklyChallenge.id,
            status: ChallengeStatus.available,
            startedAt: DateTime.now(),
          );
        }
        
        // Print debug info about the challenge status
        print("Weekly challenge loaded - ID: ${weeklyChallenge.id}");
        print("User challenge status: ${userWeeklyChallenge.status}");
      }
      
      // Load badges (just get the top 4 for dashboard)
      // TODO: Implement proper badges
      final badges = <UserBadge>[];
      
      setState(() {
        _user = user;
        _playerStats = playerStats;
        _weeklyChallenge = weeklyChallenge;
        _userWeeklyChallenge = userWeeklyChallenge;
        _badges = badges;
        _developmentPlan = loadedPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'dashboard'),
      body: Container(
        decoration: const BoxDecoration(
          // Space-themed background with stars - UPDATED GRADIENT
          gradient: LinearGradient(
            begin: Alignment.topLeft, // Match LoginPage
            end: Alignment.bottomRight, // Match LoginPage
            colors: [ // Match LoginPage
              Color(0xFF0B0033),
              Color(0xFF2A004D),
              Color(0xFF5D006C),
              Color(0xFF9A0079),
              Color(0xFFC71585),
              Color(0xFFFF4500),
            ],
             stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0], // Match LoginPage
          ),
        ),
        child: Stack(
          children: [
            // Stars background
            Positioned.fill(
              child: CustomPaint(
                painter: StarsPainter(),
              ),
            ),
            
            // Main content
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                    : _buildDashboardContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    // Get screen size to make responsive decisions
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message title (removed Academy Logo)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'COPENHAGEN ACADEMY',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Player Card and Welcome Section - Modified for mobile
            if (isSmallScreen)
              // Mobile layout - Stacked vertically
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Welcome text
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'VELKOMMEN',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _user!.fullName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // FIFA Player Card - Centered (removed profile picture functionality)
                  Center(
                    child: SizedBox(
                      width: 280, // Fixed width for small screens
                      child: FifaPlayerCard(
                        playerName: _user!.fullName,
                        position: _user!.position ?? 'ST',
                        stats: _playerStats!,
                        rating: _playerStats?.overallRating?.toInt() ?? 0,
                        cardType: _getPlayerCardType(),
                        profileImageUrl: null,
                      ),
                    ),
                  ),
                ],
              )
            else
              // --- DESKTOP LAYOUT REARRANGEMENT ---
              Column(
                children: [
                  // 1. Welcome Text Moved Above - Now includes Name, Pos, Club
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, left: 16.0), // Add left padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                      children: [
                        // Full Name
                        Text(
                          _user!.fullName.toUpperCase(), // Display full name
                          style: const TextStyle(
                            fontSize: 28, // Slightly smaller maybe?
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Position
                        Row(
                          mainAxisSize: MainAxisSize.min, // Keep row compact
                          children: [
                            Icon(Icons.person_pin_circle_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _user!.position ?? 'N/A', // Display position
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Club
                        Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
                             const SizedBox(width: 8),
                             Text(
                               _user!.currentClub ?? 'Klubløs', // Display club
                               style: const TextStyle(
                                 fontSize: 16,
                                 color: Colors.white70,
                               ),
                             ),
                           ],
                        ),
                      ],
                    ),
                  ),
                  // 2. New Row for Card and Side Sections
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align tops
                    children: [
                      // 1. Left Side: FIFA Player Card (removed profile picture functionality)
                      SizedBox(
                        width: 360, // Increased width from 300
                        child: FifaPlayerCard(
                          playerName: _user!.fullName,
                          position: _user!.position ?? 'ST',
                          stats: _playerStats!,
                          rating: _playerStats?.overallRating?.toInt() ?? 0,
                          cardType: _getPlayerCardType(),
                          profileImageUrl: null,
                        ),
                      ),

                      const SizedBox(width: 24), // Spacing between card and right column

                      // 2. Right Side: Column with Activities and Focus
                      Expanded(
                        flex: 3, // Adjust flex factor as needed
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start, // Align content to top
                          children: [
                            if (_developmentPlan != null) 
                              _buildUpcomingActivitiesSection(),
                            const SizedBox(height: 24), // Space between the two sections
                            if (_developmentPlan != null)
                              _buildDevelopmentFocusSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            // --- END DESKTOP LAYOUT REARRANGEMENT ---
            
            const SizedBox(height: 24),
            
            // Development Plan Sections (Remove from here as they are moved above in desktop layout)
            // if (_developmentPlan != null && isSmallScreen) ...[ // Only show here on small screens now
            //   const SizedBox(height: 24),
            //   _buildUpcomingActivitiesSection(),
            //   const SizedBox(height: 24),
            //   _buildDevelopmentFocusSection(),
            //   const SizedBox(height: 24),
            // ],
            
            // Weekly Challenge
            if (FeatureFlags.challengesEnabled)
              _buildWeeklyChallengeCard(),
            
            if (FeatureFlags.challengesEnabled)
              const SizedBox(height: 24),
            
            // Stats section - Modified for better mobile layout
            Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF3D007A), width: 2),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0B0057).withOpacity(0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DINE STATISTIKKER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Responsive layout for stats
                    if (isSmallScreen)
                      // Mobile layout - Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Overall rating display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF00F5A0),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F5A0).withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFF00F5A0),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'OVERALL RATING: ${_playerStats?.overallRating?.round() ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Skill progress bars in mobile view
                          _buildSkillProgressBars(),
                          
                          const SizedBox(height: 20),
                          
                          // Radar chart in mobile view (smaller)
                          SizedBox(
                            height: 240,
                            child: PlayerStatsRadarChart(
                              playerStats: _playerStats,
                              useLatestTest: true,
                              labelColors: const {
                                'PACE': Color(0xFF02D39A),
                                'SHOOTING': Color(0xFFFFD700),
                                'PASSING': Color(0xFF00ACF3),
                                'DRIBBLING': Color(0xFFBE008C),
                                'JUGGLES': Color(0xFF3875B9),
                                'FIRST TOUCH': Color(0xFFD48A29),
                              },
                            ),
                          ),
                          
                          // Stat Rating explanation
                          const Center(
                            child: Text(
                              'Dine færdigheder',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      // Desktop layout - Two columns
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Overall Rating + Radar Chart
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                // Overall rating display
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF00F5A0),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00F5A0).withOpacity(0.2),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Color(0xFF00F5A0),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'OVERALL RATING: ${_playerStats?.overallRating?.round() ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Radar Chart
                                SizedBox(
                                  height: 280,
                                  child: PlayerStatsRadarChart(
                                    playerStats: _playerStats,
                                    useLatestTest: true,
                                    labelColors: const {
                                      'PACE': Color(0xFF02D39A),
                                      'SHOOTING': Color(0xFFFFD700),
                                      'PASSING': Color(0xFF00ACF3),
                                      'DRIBBLING': Color(0xFFBE008C),
                                      'JUGGLES': Color(0xFF3875B9),
                                      'FIRST TOUCH': Color(0xFFD48A29),
                                    },
                                  ),
                                ),
                                
                                // Stat Rating explanation
                                const Center(
                                  child: Text(
                                    'Dine færdigheder',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Right column - Skill bars
                          Expanded(
                            flex: 4,
                            child: _buildSkillProgressBars(),
                          ),
                        ],
                      ),
                    
                    // Last updated timestamp in bottom left corner
                    if (_playerStats?.lastUpdated != null)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, left: 8),
                          child: Text(
                            'Sidst testet: ${_formatDate(_playerStats!.lastUpdated!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      
                    // Link to tests
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton.icon(
                          onPressed: _navigateToPlayerTests,
                          icon: const Icon(Icons.speed, size: 18),
                          label: const Text('Se alle tests'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Player Test Widget
            if (FeatureFlags.playerTestsEnabled)
              _buildPlayerTestSection(),
            
            // Add more sections as needed
          ],
        ),
      ),
    );
  }
  
  Widget _buildWeeklyChallengeCard() {
    if (_weeklyChallenge == null) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: const Color(0xFF1E1E1E),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No active challenge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
    
    // Calculate progress - default to 0 if not available
    final progress = _userWeeklyChallenge != null && _weeklyChallenge!.targetValue > 0
        ? (_userWeeklyChallenge!.currentValue / _weeklyChallenge!.targetValue).clamp(0.0, 1.0)
        : 0.0;
    
    // Determine the challenge status
    final status = _userWeeklyChallenge?.status ?? ChallengeStatus.available;
    final isCompleted = status == ChallengeStatus.completed;
    final isInProgress = status == ChallengeStatus.inProgress;
    final isAvailable = status == ChallengeStatus.available || status == ChallengeStatus.locked;
    
    // Debug log for development
    print('Challenge Widget Debug:');
    print('Challenge ID: ${_weeklyChallenge!.id}');
    print('Challenge Status: $status');
    print('Is Completed: $isCompleted');
    print('Is In Progress: $isInProgress');
    print('Is Available: $isAvailable');
    print('User Challenge: ${_userWeeklyChallenge != null ? 'Exists' : 'Null'}');
    if (_userWeeklyChallenge != null) {
      print('User Challenge Status: ${_userWeeklyChallenge!.status}');
      print('User Challenge Current Value: ${_userWeeklyChallenge!.currentValue}');
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DENNE UGES CHALLENGE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    if (_weeklyChallenge!.deadline != null) ...[
                      Text(
                        _getRemainingDays(_weeklyChallenge!.deadline!),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                Text(
                  _weeklyChallenge!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  _weeklyChallenge!.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Stats row
                Row(
                  children: [
                    // Target info
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${_weeklyChallenge!.targetValue} ${_weeklyChallenge!.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Action buttons
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT SIDE: Challenge action button - only one of these should appear
                    if (isCompleted)
                      // Completed status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isInProgress)
                      // In progress - "Indtast resultat!" button
                      ElevatedButton(
                        onPressed: () => _submitChallengeResult(_weeklyChallenge!.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50), // Green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: const Size(120, 36),
                        ),
                        child: const Text(
                          'INDTAST RESULTAT!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      // Not started - "Deltag!" button 
                      ElevatedButton(
                        onPressed: () => _optInToChallenge(_weeklyChallenge!.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          minimumSize: const Size(100, 36),
                        ),
                        child: const Text(
                          'DELTAG!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                    // RIGHT SIDE: League table button - always visible
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/league-table');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5), // Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(120, 36),
                      ),
                      child: const Text(
                        'SE LEAUGETABLE!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Progress bar at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : const Color(0xFFFFD700)
                ),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getRemainingDays(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final days = difference.inDays;
    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} left';
    }
    
    final hours = difference.inHours;
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} left';
    }
    
    final minutes = difference.inMinutes;
    return '$minutes minute${minutes > 1 ? 's' : ''} left';
  }
  
  Widget _buildBadgesSection() {
    // For demo purposes, create some mock badges if the list is empty
    final List<UserBadge> mockBadges = [
      UserBadge(
        id: '1',
        name: 'Speed Demon',
        description: 'Completed sprint test with exceptional time',
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 3)),
        badgeIcon: Icons.speed,
        badgeColor: const Color(0xFF02D39A),
        category: 'skills',
        rarity: BadgeRarity.rare,
        requirement: const BadgeRequirement(
          type: 'sprint_test',
          targetValue: 1,
          currentValue: 1,
        ),
      ),
      UserBadge(
        id: '2',
        name: 'Sharpshooter',
        description: 'Scored 8+ in shooting accuracy test',
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 7)),
        badgeIcon: Icons.sports_soccer,
        badgeColor: const Color(0xFFFFD700),
        category: 'skills',
        rarity: BadgeRarity.uncommon,
        requirement: const BadgeRequirement(
          type: 'shooting_test',
          targetValue: 8,
          currentValue: 9,
        ),
      ),
      UserBadge(
        id: '3',
        name: 'Master Dribbler',
        description: 'Completed the dribbling course in record time',
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 14)),
        badgeIcon: Icons.directions_run,
        badgeColor: const Color(0xFFBE008C),
        category: 'skills',
        rarity: BadgeRarity.epic,
        requirement: const BadgeRequirement(
          type: 'dribbling_test',
          targetValue: 1,
          currentValue: 1,
        ),
      ),
      UserBadge(
        id: '4',
        name: 'Endurance King',
        description: 'Completed 30-day training streak',
        isEarned: true,
        earnedDate: DateTime.now().subtract(const Duration(days: 21)),
        badgeIcon: Icons.fitness_center,
        badgeColor: const Color(0xFF00ACF3),
        category: 'consistency',
        rarity: BadgeRarity.legendary,
        requirement: const BadgeRequirement(
          type: 'training_streak',
          targetValue: 30,
          currentValue: 30,
        ),
      ),
    ];
    
    // Use mock badges for display if the actual list is empty
    final earnedBadges = _badges.where((badge) => badge.isEarned).toList();
    final displayBadges = earnedBadges.isEmpty ? mockBadges : earnedBadges;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: [
          // Badge content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Badges',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BadgesPage(badges: _badges.isEmpty ? mockBadges : _badges),
                          ),
                        );
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                displayBadges.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Complete challenges to earn badges!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: displayBadges.length > 4 ? 4 : displayBadges.length,
                        itemBuilder: (context, index) {
                          final badge = displayBadges[index];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Badge icon with glow
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: badge.badgeColor.withOpacity(0.2),
                                  border: Border.all(
                                    color: badge.badgeColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: badge.badgeColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  badge.badgeIcon,
                                  color: badge.badgeColor,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Badge name
                              Text(
                                badge.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
              ],
            ),
          ),
          
          // Coming soon overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'KOMMER SNART!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.8),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSkillProgressBars() {
    final Map<String, Color> skillColors = {
      'Pace': const Color(0xFF02D39A),
      'Shooting': const Color(0xFFFFD700),
      'Passing': const Color(0xFF00ACF3),
      'Dribbling': const Color(0xFFBE008C),
      'Defense': const Color(0xFF3875B9),
      'Physical': const Color(0xFFD48A29),
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tekniske færdigheder',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SkillProgressBar(
          skillName: 'Pace',
          currentValue: _playerStats!.pace.toInt(),
          progressColor: skillColors['Pace']!,
        ),
        SkillProgressBar(
          skillName: 'Shooting',
          currentValue: _playerStats!.shooting.toInt(),
          progressColor: skillColors['Shooting']!,
        ),
        SkillProgressBar(
          skillName: 'Passing',
          currentValue: _playerStats!.passing.toInt(),
          progressColor: skillColors['Passing']!,
        ),
        SkillProgressBar(
          skillName: 'Dribbling',
          currentValue: _playerStats!.dribbling.toInt(),
          progressColor: skillColors['Dribbling']!,
        ),
        SkillProgressBar(
          skillName: 'Juggles',
          currentValue: _playerStats!.juggles.toInt(),
          progressColor: skillColors['Defense']!,
        ),
        SkillProgressBar(
          skillName: 'First Touch',
          currentValue: _playerStats!.firstTouch?.toInt() ?? 0,
          progressColor: skillColors['Physical']!,
        ),
      ],
    );
  }

  // Determine player card type based on various criteria
  CardType _getPlayerCardType() {
    final rating = _playerStats?.overallRating?.toInt() ?? 0;
    
    // Icon card for exceptional players (95+ rating)
    if (rating >= 95) {
      return CardType.icon;
    }
    
    // Check if player has broken any test records
    // This is an async operation, but for UI purposes we'll use any cached values or previous results
    _checkForRecordBreakerStatus();
    
    // If we previously determined they've broken records, show record breaker card
    if (_hasRecordBreakingScores) {
      return CardType.record_breaker;
    }
    
    // Record breaker for players who broke test records
    // For demo purposes, let's check if any stats are exceptionally high
    if ((_playerStats?.pace ?? 0) >= 95 || 
        (_playerStats?.shooting ?? 0) >= 95 || 
        (_playerStats?.passing ?? 0) >= 95 || 
        (_playerStats?.dribbling ?? 0) >= 95 || 
        (_playerStats?.juggles ?? 0) >= 95 || 
        (_playerStats?.firstTouch ?? 0) >= 95) {
      return CardType.record_breaker;
    }
    
    // Hero card for team captains
    if (_user?.isCaptain == true) {
      return CardType.hero;
    }
    
    // Team of the Week for high-rated players (85+)
    if (rating >= 85) {
      return CardType.totw;
    }
    
    // Future Stars for promising players (80-84)
    if (rating >= 80) {
      return CardType.future;
    }
    
    // Default normal card
    return CardType.normal;
  }
  
  // Check if player has broken any test records
  Future<void> _checkForRecordBreakerStatus() async {
    try {
      // Get player tests from service
      final tests = await PlayerTestsService.getPlayerTests(context);
      
      // Check each test for record breaking scores
      for (final test in tests) {
        if (test.isPassingRecord == true ||
            test.isSprintRecord == true ||
            test.isFirstTouchRecord == true ||
            test.isShootingRecord == true ||
            test.isJugglingRecord == true ||
            test.isDribblingRecord == true) {
          // Set flag and update state if needed
          if (!_hasRecordBreakingScores) {
            setState(() {
              _hasRecordBreakingScores = true;
            });
          }
          break;
        }
      }
    } catch (e) {
      print('Error checking for record breaker status: $e');
    }
  }

  Future<void> _optInToChallenge(String challengeId) async {
    setState(() {
      _isLoading = true; // Show loading state
    });
    
    try {
      final success = await ChallengeService.optInToChallenge(challengeId);
      
      if (success) {
        // Show popup
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1C006C),
                title: const Text(
                  'Du er tilmeldt!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: const Text(
                  'Du er nu tilmeldt udfordringen. God fornøjelse!',
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Color(0xFFFFA500)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        
        // Immediate UI update while waiting for full data refresh
        if (mounted && _userWeeklyChallenge != null) {
          setState(() {
            _userWeeklyChallenge = _userWeeklyChallenge!.copyWith(
              status: ChallengeStatus.inProgress,
            );
          });
        }
        
        // Reload complete data to ensure everything is in sync
        await _loadUserData(); 
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to opt in to the challenge. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error opting in to challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to opt in to the challenge: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading state
        });
      }
    }
  }

  Future<void> _submitChallengeResult(String challengeId) async {
    // Verify that user has opted in to the challenge before allowing result submission
    if (_userWeeklyChallenge?.status != ChallengeStatus.inProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du skal først tilmelde dig udfordringen før du kan indtaste et resultat.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  
    final TextEditingController resultController = TextEditingController();
    bool isSubmitting = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Indtast dit resultat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Indtast dit resultat for denne udfordring:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resultController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'f.eks. 42',
                  labelText: 'Dit resultat',
                ),
              ),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANNULLER'),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Validate input
                      final resultText = resultController.text.trim();
                      if (resultText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Indtast venligst et resultat'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      // Parse to double
                      double? value;
                      try {
                        value = double.parse(resultText);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Indtast et gyldigt tal'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        isSubmitting = true;
                      });
                      
                      // Submit result to API
                      try {
                        final success = await ChallengeService.submitChallengeResult(
                          challengeId,
                          value,
                        );
                        
                        Navigator.of(context).pop(); // Close dialog
                        
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Resultat indsendt!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          // Immediate UI update while waiting for full data refresh
                          if (mounted && _userWeeklyChallenge != null) {
                            setState(() {
                              _userWeeklyChallenge = _userWeeklyChallenge!.copyWith(
                                currentValue: value!.toInt(),
                                // If value exceeds target, mark as completed
                                status: value! >= (_weeklyChallenge?.targetValue ?? double.infinity)
                                    ? ChallengeStatus.completed
                                    : ChallengeStatus.inProgress,
                              );
                            });
                          }
                          
                          // Reload user data to reflect the new status
                          _loadUserData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kunne ikke indsende resultat. Prøv igen senere.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.of(context).pop(); // Close dialog on error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fejl: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('INDSEND'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format dates
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _navigateToPlayerTests() {
    // Navigate to a dedicated player tests page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerTestsPage(),
      ),
    );
  }

  Widget _buildPlayerTestSection() {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3D007A), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0B0057).withOpacity(0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and icon
            const Row(
              children: [
                Icon(Icons.speed, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'DINE TESTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Brief summary of the latest test
            if (_playerStats?.lastUpdated != null) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sidste test: ${_formatDate(_playerStats!.lastUpdated!)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Show some key stats
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildStatBadge('Pace', _playerStats!.pace.round()),
                      _buildStatBadge('Shooting', _playerStats!.shooting.round()),
                      _buildStatBadge('Passing', _playerStats!.passing.round()),
                      _buildStatBadge('Dribbling', _playerStats!.dribbling.round()),
                      _buildStatBadge('Juggles', _playerStats!.juggles.round()),
                      _buildStatBadge('First Touch', _playerStats!.firstTouch.round()),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              )
            else
              const Text(
                'Du har endnu ikke taget nogen tests. Tag din første test nu!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            
            // Button to access full test history
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: _navigateToPlayerTests,
                  icon: const Icon(Icons.add_chart, size: 18),
                  label: const Text('Tag en ny test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatBadge(String label, int value) {
    Color badgeColor;
    if (value >= 80) {
      badgeColor = Colors.green;
    } else if (value >= 60) {
      badgeColor = Colors.amber;
    } else {
      badgeColor = Colors.red.shade400;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingActivitiesSection() {
    // For now, we'll show a "Coming Soon" message since trainingSessions aren't supported yet
    return _buildInfoCard(
      icon: Icons.event_note_outlined,
      title: 'Kommende Aktiviteter',
      child: const Text(
        'Træningsplan integration kommer snart!', 
        style: TextStyle(color: Colors.white70)
      ),
      actionButton: TextButton(
        onPressed: () {
          // Navigate to the full development plan page
          Navigator.pushNamed(context, '/development-plan');
        },
        child: const Text('Se Udviklingsfokus', style: TextStyle(color: Color(0xFFFFD700))) 
      )
    );
  }

  // Placeholder method for future implementation
  Widget _buildActivityItem(TrainingSession session) {
    final List<String> weekdays = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];
    final weekdayStr = session.weekday >= 1 && session.weekday <= 7 ? weekdays[session.weekday - 1] : 'Ukendt';
    final timeStr = session.startTime ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$weekdayStr $timeStr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              session.title,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentFocusSection() {
    if (_developmentPlan == null || _developmentPlan!.focusAreas.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no plan or focus areas
    }
    
    final areasToShow = _developmentPlan!.focusAreas
      .where((area) => !area.isCompleted) // Only show active focus areas
      .take(3) // Limit to 3 for dashboard
      .toList();

    if (areasToShow.isEmpty) {
        return _buildInfoCard(
        icon: Icons.center_focus_weak_outlined,
        title: 'Udviklingsfokus',
        child: const Text('Ingen aktive fokusområder defineret.', style: TextStyle(color: Colors.white70)),
      );
    }

    return _buildInfoCard(
      icon: Icons.track_changes_outlined,
      title: 'Udviklingsfokus',
      child: Column(
        children: areasToShow.map((area) => _buildFocusAreaItem(area)).toList(),
      ),
       actionButton: TextButton(
        onPressed: () {
           // Navigate to the full development plan page (focus tab)
          // TODO: Add logic to navigate directly to the focus tab if possible
          Navigator.pushNamed(context, '/development-plan');
        },
        child: const Text('Se Alle Områder', style: TextStyle(color: Color(0xFFFFD700))) 
      )
    );
  }

  Widget _buildFocusAreaItem(FocusArea area) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white.withOpacity(0.6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              area.title,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build consistent card sections
  Widget _buildInfoCard({required IconData icon, required String title, required Widget child, Widget? actionButton}) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3D007A), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0B0057).withOpacity(0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(
                   children: [
                     Icon(icon, color: Colors.white),
                     const SizedBox(width: 8),
                     Text(
                       title,
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 18, // Smaller title for these cards
                         fontWeight: FontWeight.bold,
                         letterSpacing: 1.2,
                       ),
                     ),
                   ],
                 ),
                 if (actionButton != null) actionButton,
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

// Custom painter to draw stars for the space theme
class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final starPaint = Paint()..color = Colors.white;
    
    // Draw small stars
    for (int i = 0; i < 100; i++) {
      final x = (random * (i + 1) * 13) % size.width;
      final y = (random * (i + 1) * 17) % size.height;
      final radius = ((random * (i + 1)) % 2) + 0.5;
      
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
    
    // Draw medium stars
    for (int i = 0; i < 20; i++) {
      final x = (random * (i + 1) * 29) % size.width;
      final y = (random * (i + 1) * 31) % size.height;
      
      final starPath = Path();
      final outerRadius = 2.0 + ((random * (i + 1)) % 3);
      final innerRadius = outerRadius * 0.4;
      final centerX = x;
      final centerY = y;
      
      for (int j = 0; j < 10; j++) {
        final angle = j * 36 * (3.14159 / 180);
        final radius = j % 2 == 0 ? outerRadius : innerRadius;
        final pointX = centerX + radius * math.cos(angle);
        final pointY = centerY + radius * math.sin(angle);
        
        if (j == 0) {
          starPath.moveTo(pointX, pointY);
        } else {
          starPath.lineTo(pointX, pointY);
        }
      }
      
      starPath.close();
      
      // Add a glow effect
      final colors = [
        Colors.yellow.withOpacity(0.7),
        Colors.yellow.withOpacity(0.5),
        Colors.yellow.withOpacity(0.3),
        Colors.yellow.withOpacity(0.1),
        Colors.yellow.withOpacity(0.0),
      ];
      
      canvas.drawPath(starPath, Paint()..color = colors[random % 5]);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 