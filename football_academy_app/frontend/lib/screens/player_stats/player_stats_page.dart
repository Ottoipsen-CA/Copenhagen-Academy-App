import 'package:flutter/material.dart';
import '../../models/player_stats.dart';
import '../../services/player_stats_service.dart';
import '../../widgets/player_card.dart';
import '../../widgets/navigation_drawer.dart';

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
      appBar: AppBar(
        title: const Text('Player Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayerStats,
          ),
        ],
      ),
      drawer: const CustomNavigationDrawer(currentPage: 'player_stats'),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty 
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_playerStats == null) {
      return const Center(
        child: Text('No player stats available'),
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
                playerPosition: 'CM', // In a real app, fetch position from user profile
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Details
            const Text(
              'Stats Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Improve Your Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Complete challenges to improve your stats\n'
                      '• Higher completion scores give bigger rating boosts\n'
                      '• Different challenges affect different stats\n'
                      '• Consistently complete challenges to reach top ratings',
                      style: TextStyle(
                        fontSize: 14,
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
                      color: Colors.grey[300],
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
} 