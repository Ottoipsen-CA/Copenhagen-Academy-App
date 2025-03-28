import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/player_stats.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/player_stats_radar_chart.dart';
import '../../widgets/fifa_player_card.dart';
import '../../widgets/skill_progress_bar.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? _user;
  PlayerStats? _playerStats;
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
      
      // TODO: Implement loading player stats from API
      // For now, we'll use sample data
      final playerStats = PlayerStats(
        playerId: int.parse(user.id!),
        pace: 75,
        shooting: 68,
        passing: 72,
        dribbling: 80,
        defense: 60,
        physical: 65,
        overallRating: 70,
      );
      
      setState(() {
        _user = user;
        _playerStats = playerStats;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(36),
            const SizedBox(width: 10),
            const Text('Copenhagen Academy'),
          ],
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

  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // Soccer ball top part
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.5),
                  topRight: Radius.circular(size * 0.5),
                ),
              ),
            ),
          ),
          
          // Text placeholders for "COPENHAGEN" and "ACADEMY"
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size * 0.05),
                Container(
                  width: size * 0.7,
                  height: size * 0.07,
                  color: Colors.transparent,
                ),
                SizedBox(height: size * 0.05),
                Container(
                  width: size * 0.7,
                  height: size * 0.07,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
          
          // Stars at the bottom
          Positioned(
            bottom: size * 0.1,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.01),
                  child: Icon(
                    Icons.star,
                    color: Colors.white,
                    size: size * 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                        '${_user!.fullName.split(' ')[0]}!',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700), // Gold color
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // XP Bar Section
                      const Text(
                        'XP BAR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700), // Gold color
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // XP Progress Bar
                      Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF173968), // Dark blue
                        ),
                        child: Stack(
                          children: [
                            // Gradient progress
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _xpProgress / _xpTarget,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF02D39A), // Teal
                                      Color(0xFF06F0FF), // Cyan
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      // Progression text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progression',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$_xpProgress/$_xpTarget',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Performance Analysis with Radar Chart
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
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Overall Rating: 70 (Silver)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Right column - Challenges & Goals
                        Expanded(
                          flex: 3,
                          child: _buildChallengesColumn(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Individual skill progress bars
                    _buildSkillProgressBars(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Daily Challenge and Gold Level
            Row(
              children: [
                // Daily Challenge Card
                Expanded(
                  flex: 7,
                  child: _buildDailyChallenge(),
                ),
                const SizedBox(width: 16),
                // Gold Level
                Expanded(
                  flex: 3,
                  child: _buildGoldLevel(),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Recent activities
            _buildRecentActivitiesCard(),
            
            const SizedBox(height: 40),
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

  Widget _buildChallengesColumn() {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly challenge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF5757).withOpacity(0.1),
                  const Color(0xFFFF8C8C).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF5757).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Color(0xFFFF5757),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Weekly Challenge',
                      style: TextStyle(
                        color: Color(0xFFFF5757),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Score 5 goals in practice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.6, // 3 out of 5
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                              color: Color(0xFFFF5757),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '3/5',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reward: 150 XP + Speed badge',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Unlocked badges
          const Text(
            'Your Badges',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildBadge(
                icon: Icons.speed,
                color: const Color(0xFF02D39A),
                isActive: true,
                label: 'Speedster',
              ),
              const SizedBox(width: 8),
              _buildBadge(
                icon: Icons.sports_soccer,
                color: const Color(0xFFFFD700),
                isActive: true,
                label: 'Finisher',
              ),
              const SizedBox(width: 8),
              _buildBadge(
                icon: Icons.fitness_center,
                color: const Color(0xFFD48A29),
                isActive: false,
                label: 'Power',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Next unlock
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.1),
                  const Color(0xFFEBC137).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lock_open,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Next Unlock',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Unlock Shooting Badge when SHO > 70',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required bool isActive,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? color : Colors.white.withOpacity(0.3),
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
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

  Widget _buildDailyChallenge() {
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD700),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Color(0xFF0B0057),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Daily Challenge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFFF5757),
                  ),
                  child: const Text(
                    'VIEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete 3 drills',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
                Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
                Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
                Icon(Icons.star_border, color: Color(0xFFFFD700), size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldLevel() {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              color: Color(0xFFFFD700),
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gold III',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
            const Text(
              '2 hours ago',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
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