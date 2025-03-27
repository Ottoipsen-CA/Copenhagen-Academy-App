import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/player_stats.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/player_stats_radar_chart.dart';

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
        playerId: user.id!,
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
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildDashboardContent(),
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
            // Welcome message
            Text(
              'Welcome, ${_user!.fullName}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user!.position != null ? 'Position: ${_user!.position}' : '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Player stats card
            _buildPlayerStatsCard(),
            const SizedBox(height: 24),
            
            // Quick access card
            _buildQuickAccessCard(),
            const SizedBox(height: 24),
            
            // Recent activities
            _buildRecentActivitiesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Player Attributes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rating: ${_playerStats!.overallRating.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Player stats radar chart
            SizedBox(
              height: 200,
              child: PlayerStatsRadarChart(stats: _playerStats!),
            ),
            const SizedBox(height: 16),
            
            // Individual attributes
            Row(
              children: [
                _buildAttributeItem('Pace', _playerStats!.pace),
                _buildAttributeItem('Shooting', _playerStats!.shooting),
                _buildAttributeItem('Passing', _playerStats!.passing),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAttributeItem('Dribbling', _playerStats!.dribbling),
                _buildAttributeItem('Defense', _playerStats!.defense),
                _buildAttributeItem('Physical', _playerStats!.physical),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeItem(String label, double value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAttributeColor(value),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toInt().toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getAttributeColor(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttributeColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 65) return Colors.amber;
    return Colors.red;
  }

  Widget _buildQuickAccessCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAccessButton(
                  icon: Icons.fitness_center,
                  label: 'Training Plan',
                  onTap: () {
                    // TODO: Navigate to training plan
                  },
                ),
                _buildQuickAccessButton(
                  icon: Icons.video_library,
                  label: 'Exercises',
                  onTap: () {
                    // TODO: Navigate to exercises
                  },
                ),
                _buildQuickAccessButton(
                  icon: Icons.emoji_events,
                  label: 'Achievements',
                  onTap: () {
                    // TODO: Navigate to achievements
                  },
                ),
                _buildQuickAccessButton(
                  icon: Icons.chat,
                  label: 'Chat',
                  onTap: () {
                    // TODO: Navigate to chat
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard() {
    // Placeholder for recent activities
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: Icons.fitness_center,
              title: 'Completed Training Session',
              subtitle: 'Speed and Agility Workout',
              time: '2 hours ago',
            ),
            const Divider(),
            _buildActivityItem(
              icon: Icons.emoji_events,
              title: 'Earned New Badge',
              subtitle: 'Consistent Performer',
              time: '1 day ago',
            ),
            const Divider(),
            _buildActivityItem(
              icon: Icons.chat,
              title: 'New Message',
              subtitle: 'From Coach David',
              time: '2 days ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
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
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 