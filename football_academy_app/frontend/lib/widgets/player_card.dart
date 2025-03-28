import 'package:flutter/material.dart';
import '../models/player_stats.dart';
import '../services/auth_service.dart';

class PlayerCard extends StatelessWidget {
  final PlayerStats stats;
  final String playerName;
  final String? playerPosition;
  final String? imageUrl;
  final bool showDetailedStats;

  const PlayerCard({
    Key? key,
    required this.stats,
    required this.playerName,
    this.playerPosition,
    this.imageUrl,
    this.showDetailedStats = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: showDetailedStats ? 320 : 180,
        height: showDetailedStats ? 420 : 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getRatingColor(stats.overallRating).withOpacity(0.7),
              _getRatingColor(stats.overallRating),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildCardHeader(),
            Expanded(
              child: showDetailedStats 
                  ? _buildDetailedStats(context)
                  : _buildSimpleStats(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Rating
              Text(
                stats.overallRating.round().toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // Position
              if (playerPosition != null)
                Text(
                  playerPosition!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          // Avatar/Image
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      imageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.blueGrey,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    return Column(
      children: [
        // Player Name
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            playerName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Stats
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(context, 'PAC', stats.pace.round()),
              _buildStatColumn(context, 'SHO', stats.shooting.round()),
              _buildStatColumn(context, 'PAS', stats.passing.round()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(context, 'DRI', stats.dribbling.round()),
              _buildStatColumn(context, 'DEF', stats.defense.round()),
              _buildStatColumn(context, 'PHY', stats.physical.round()),
            ],
          ),
        ),
        
        // Last Updated
        const Spacer(),
        if (stats.lastUpdated != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: ${_formatDate(stats.lastUpdated!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleStats(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player Name
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            playerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Top 3 Stats
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _getTopThreeStats().entries.map((entry) {
              return _buildStatColumn(context, entry.key, entry.value.round());
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatColor(value),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double> _getTopThreeStats() {
    final Map<String, double> allStats = {
      'PAC': stats.pace,
      'SHO': stats.shooting,
      'PAS': stats.passing,
      'DRI': stats.dribbling,
      'DEF': stats.defense,
      'PHY': stats.physical,
    };
    
    // Sort by value
    final sortedStats = allStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top 3
    return Map.fromEntries(sortedStats.take(3));
  }

  Color _getRatingColor(double rating) {
    if (rating >= 86) {
      return Colors.red[700]!; // High rated
    } else if (rating >= 80) {
      return Colors.orange[700]!; // Gold
    } else if (rating >= 75) {
      return Colors.yellow[700]!; // Silver elite
    } else if (rating >= 70) {
      return Colors.amber; // Silver
    } else if (rating >= 65) {
      return Colors.green; // Bronze elite
    } else {
      return Colors.brown; // Bronze
    }
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
    return '${date.day}/${date.month}/${date.year}';
  }
} 