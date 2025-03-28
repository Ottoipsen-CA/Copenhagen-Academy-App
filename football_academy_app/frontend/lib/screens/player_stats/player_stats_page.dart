import 'package:flutter/material.dart';
import '../../models/player_stats.dart';
import '../../services/player_stats_service.dart';
import '../../widgets/player_card.dart';
import '../../widgets/navigation_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/colors.dart';
import '../../widgets/gradient_background.dart';

class PlayerStatsPage extends StatefulWidget {
  const PlayerStatsPage({Key? key}) : super(key: key);

  @override
  State<PlayerStatsPage> createState() => _PlayerStatsPageState();
}

class _PlayerStatsPageState extends State<PlayerStatsPage> {
  PlayerStats? _playerStats;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadPlayerStats();
  }
  
  Future<void> _loadPlayerStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final stats = await PlayerStatsService.getPlayerStats();
      setState(() {
        _playerStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load player stats: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Player Stats',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPlayerStats,
          ),
        ],
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'player_stats'),
      body: GradientBackground(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage.isNotEmpty 
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white)))
                : _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_playerStats == null) {
      return const Center(
        child: Text(
          'No player stats available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FIFA Card
            Center(
              child: PlayerCard(
                stats: _playerStats!,
                playerName: 'Your Player', // In a real app, fetch user's name
                playerPosition: 'RW', // Match the login screen position
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Details
            const Text(
              'Stats Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats progress
            _buildStatProgressBar('Pace', _playerStats!.pace),
            const SizedBox(height: 8),
            _buildStatProgressBar('Shooting', _playerStats!.shooting),
            const SizedBox(height: 8),
            _buildStatProgressBar('Passing', _playerStats!.passing),
            const SizedBox(height: 8),
            _buildStatProgressBar('Dribbling', _playerStats!.dribbling),
            const SizedBox(height: 8),
            _buildStatProgressBar('Defense', _playerStats!.defense),
            const SizedBox(height: 8),
            _buildStatProgressBar('Physical', _playerStats!.physical),
            
            const SizedBox(height: 24),
            
            // Info text
            Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Improve Your Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Complete challenges to improve your stats\n'
                      '• Higher completion scores give bigger rating boosts\n'
                      '• Different challenges affect different stats\n'
                      '• Consistently complete challenges to reach top ratings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Overall Rating: ${_playerStats!.overallRating.round()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Updated: ${_playerStats!.lastUpdated != null ? _formatDate(_playerStats!.lastUpdated!) : "Not available"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatProgressBar(String label, double value) {
    final percentage = (value / 99.0).clamp(0.0, 1.0);
    
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // Background
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatColor(value.toInt()),
                            _getStatColor(value.toInt()).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Value text
                  Center(
                    child: Text(
                      value.round().toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getStatColor(int value) {
    if (value >= 90) {
      return Colors.green[700]!;
    } else if (value >= 80) {
      return Colors.green;
    } else if (value >= 70) {
      return Colors.lime;
    } else if (value >= 60) {
      return Colors.amber;
    } else if (value >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
} 