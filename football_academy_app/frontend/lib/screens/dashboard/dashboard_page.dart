import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/player_stats.dart';
import '../../models/challenge.dart';
import '../../models/badge.dart';
import '../../services/auth_service.dart';
import '../../services/player_stats_service.dart';
import '../../services/challenge_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/player_stats_radar_chart.dart';
import '../../widgets/fifa_player_card.dart';
import '../../widgets/skill_progress_bar.dart';
import 'dart:math' as math;

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
      
      // Load player stats from the service
      final playerStats = await PlayerStatsService.getPlayerStats();
      if (playerStats == null) {
        throw Exception("Failed to load player stats");
      }
      
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
              children: [
                // FIFA Player Card - Left corner
                FifaPlayerCard(
                  playerName: _user!.fullName,
                  position: _user!.position ?? 'ST',
                  stats: _playerStats!,
                  rating: _playerStats!.overallRating.toInt(),
                  nationality: '🇦🇺', // Australian flag as example
                  cardType: _playerStats!.overallRating >= 85 ? CardType.totw : 
                           _playerStats!.overallRating >= 80 ? CardType.future : 
                           CardType.normal,
                ),
                const SizedBox(width: 30),
                
                // Welcome text and progress bar
                Expanded(
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
                      const SizedBox(height: 16),
                      // XP Progress bar
                      _buildXpProgressBar(),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Weekly Challenge
            _buildWeeklyChallengeCard(),
            
            const SizedBox(height: 24),
            
            // Stats and badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radar chart - left side
                Expanded(
                  flex: 3,
                  child: _buildStatsCard(),
                ),
                const SizedBox(width: 16),
                // Badges - right side
                Expanded(
                  flex: 2,
                  child: _buildBadgesSection(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Performance data
            _buildPerformanceSection(),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengesPage(),
            ),
          );
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
    // Filter to only show earned badges and take the first 3
    final earnedBadges = _badges.where((badge) => badge.isEarned).take(3).toList();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.black.withOpacity(0.5),
      child: Padding(
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BadgesPage(badges: _badges),
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
            earnedBadges.isEmpty
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: earnedBadges.map((badge) {
                      return Column(
                        children: [
                          // Badge icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: badge.badgeColor.withOpacity(0.2),
                              border: Border.all(
                                color: badge.badgeColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              badge.badgeIcon,
                              color: badge.badgeColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Badge name
                          SizedBox(
                            width: 80,
                            child: Text(
                              badge.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildXpProgressBar() {
    return LinearProgressIndicator(
      value: _xpProgress / _xpTarget,
      backgroundColor: Colors.white.withOpacity(0.2),
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
      minHeight: 18,
      borderRadius: BorderRadius.circular(9),
    );
  }

  Widget _buildStatsCard() {
    return Card(
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
            
            // Three-column layout: Player Info, Radar Chart, Challenges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Player Progression
                Expanded(
                  flex: 3,
                  child: _buildPlayerProgressionColumn(),
                ),
                
                // Center column - Radar Chart
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: PlayerStatsRadarChart(
                          stats: _playerStats!,
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
                  flex: 3,
                  child: _buildSkillProgressBars(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerProgressionColumn() {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Rank & Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFAAA9AD).withOpacity(0.3), // Silver background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFAAA9AD), width: 1),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield,
                  color: Color(0xFFAAA9AD),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Silver II',
                  style: TextStyle(
                    color: Color(0xFFAAA9AD),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Player position and rating
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Position',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'ST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Striker',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Active boosts
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF02D39A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF02D39A).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: Color(0xFF02D39A),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Active Boosts',
                      style: TextStyle(
                        color: Color(0xFF02D39A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActiveBoost(
                  label: 'Dribbling +5',
                  duration: '22h remaining',
                  color: const Color(0xFFBE008C),
                ),
                const SizedBox(height: 4),
                _buildActiveBoost(
                  label: 'Stamina +3',
                  duration: '2d remaining',
                  color: const Color(0xFFD48A29),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Next level progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Next Level',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06F0FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Level 6',
                      style: TextStyle(
                        color: Color(0xFF06F0FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: const Color(0xFF173968), // Dark blue
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _xpProgress / _xpTarget,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF02D39A), // Teal
                          Color(0xFF06F0FF), // Cyan
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_xpProgress/$_xpTarget XP',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
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
          skillName: 'Defense',
          currentValue: _playerStats!.defense.toInt(),
          progressColor: skillColors['Defense']!,
        ),
        SkillProgressBar(
          skillName: 'Physical',
          currentValue: _playerStats!.physical.toInt(),
          progressColor: skillColors['Physical']!,
        ),
      ],
    );
  }

  Widget _buildActiveBoost({
    required String label,
    required String duration,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        Text(
          duration,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
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
              'Recent Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildActivityItem(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF02D39A),
              iconBgColor: const Color(0xFF02D39A).withOpacity(0.2),
              title: 'Finished Training Session',
              subtitle: 'Ball Control Drills',
              time: '2 hours ago',
              showDivider: true,
            ),
            _buildActivityItem(
              icon: Icons.star,
              iconColor: const Color(0xFFFFD700),
              iconBgColor: const Color(0xFFFFD700).withOpacity(0.2),
              title: 'New Badge Earned!',
              subtitle: 'Speedster',
              time: '1 day ago',
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String time,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(color: Color(0xFF3D007A), thickness: 1),
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