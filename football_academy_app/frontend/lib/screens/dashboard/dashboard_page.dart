import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/player_stats.dart';
import '../../models/challenge.dart';
import '../../models/badge.dart';
import '../../models/player_test.dart';
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

// Import main feature flag
import '../../main.dart';

// Import pages
import '../badges/badges_page.dart';
import '../challenges/challenges_page.dart';

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
  bool _isLoading = true;
  String? _errorMessage;
  int _xpProgress = 440;
  int _xpTarget = 1200;
  bool _hasRecordBreakingScores = false;

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
      
      // Use mock data for player stats
      final playerStats = PlayerStats(
        pace: 85.0,
        shooting: 84.0,
        passing: 78.0,
        dribbling: 88.0,
        juggles: 75.0,
        firstTouch: 82.0,
        overallRating: 83.0,
        lastUpdated: DateTime.now(),
      );
      
      // Initialize challenges
      await ChallengeService.initializeUserChallenges();
      
      // Load active challenge
      final weeklyChallenge = await ChallengeService.getWeeklyChallenge();
      
      // Load user challenge status
      UserChallenge? userWeeklyChallenge;
      if (weeklyChallenge != null) {
        final userChallenges = await ChallengeService.getUserChallenges();
        userWeeklyChallenge = userChallenges.firstWhere(
          (uc) => uc.challengeId == weeklyChallenge.id,
          orElse: () => UserChallenge(
            challengeId: weeklyChallenge.id,
            status: ChallengeStatus.available,
            startedAt: DateTime.now(),
          ),
        );
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
        title: const Text('Dashboard'),
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
          // Space-themed background with stars
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark blue/purple
              Color(0xFF1C006C), // Mid purple
              Color(0xFF3D007A), // Lighter purple
            ],
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
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message with Academy Logo
            Center(
              child: Column(
                children: [
                  _buildLogo(80),
                  const SizedBox(height: 16),
                  const Text(
                    'COPENHAGEN ACADEMY',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Player Card and Welcome Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome text (left side)
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _user!.firstName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // FIFA Player Card - Center
                FifaPlayerCard(
                  playerName: _user!.fullName,
                  position: _user!.position ?? 'ST',
                  stats: _playerStats!,
                  rating: _playerStats?.overallRating?.toInt() ?? 0,
                  nationality: '🇦🇺', // Australian flag as example
                  playerImageUrl: 'https://raw.githubusercontent.com/ottoipsen/football_academy_assets/main/player_photos/player_photo.jpg',
                  cardType: _getPlayerCardType(),
                ),
                
                // Empty space on the right for balance
                Expanded(
                  flex: 1,
                  child: Container(),
                ),
              ],
            ),
            
            // Weekly Challenge
            if (FeatureFlags.challengesEnabled)
              _buildWeeklyChallengeCard(),
            
            if (FeatureFlags.challengesEnabled)
              const SizedBox(height: 24),
            
            // Stats section
            Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF3D007A), width: 2),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF0B0057).withOpacity(0.6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Player Performance & Skills',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Two-column layout: Radar Chart and Skill Bars
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Radar Chart
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 280,
                                child: PlayerStatsRadarChart(
                                  playerStats: _playerStats,
                                  labelColors: const {
                                    'PACE': Color(0xFF02D39A),
                                    'SHOOTING': Color(0xFFFFD700),
                                    'PASSING': Color(0xFF00ACF3),
                                    'DRIBBLING': Color(0xFFBE008C),
                                    'DEFENSE': Color(0xFF3875B9),
                                    'PHYSICAL': Color(0xFFD48A29),
                                  },
                                ),
                              ),
                              // Stat Rating explanation
                              const Center(
                                child: Text(
                                  'Your skill ratings by area',
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
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Player Tests Widget
            if (FeatureFlags.playerTestsEnabled)
              const PlayerTestWidget(),
            
            if (FeatureFlags.playerTestsEnabled)
              const SizedBox(height: 24),
            
            // Badges section
            if (FeatureFlags.badgesEnabled)
              _buildBadgesSection(),
              
            if (FeatureFlags.badgesEnabled)
              const SizedBox(height: 24),
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
              'No active weekly challenge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
    
    // Calculate progress
    final progress = _userWeeklyChallenge != null 
        ? _userWeeklyChallenge!.currentValue / _weeklyChallenge!.targetValue 
        : 0.0;
    final isCompleted = _userWeeklyChallenge?.status == ChallengeStatus.completed;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () {
          if (FeatureFlags.challengesEnabled) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChallengesPage(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16.0),
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
                        'WEEKLY CHALLENGE',
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
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Participants info
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
                      
                      const Spacer(),
                      
                      // User status
                      if (isCompleted) 
                        // Completed
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
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
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'COMPLETED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_userWeeklyChallenge?.status == ChallengeStatus.inProgress)
                        // In progress
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.show_chart,
                                color: Colors.blue,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Not started
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.orange,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'START',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
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
                  value: progress.clamp(0.0, 1.0),
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
          'Technical Skills',
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

  // Build the academy logo
  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'CA',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0B0057),
          ),
        ),
      ),
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