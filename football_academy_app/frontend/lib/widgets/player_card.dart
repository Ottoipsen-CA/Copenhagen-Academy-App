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
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E22AA), // Dark blue
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  stats.overallRating.round().toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              // Position
              if (playerPosition != null)
                Text(
                  playerPosition!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E22AA),
                  ),
                ),
            ],
          ),
          // Avatar/Image
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF9500),
            ),
            child: imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      imageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 70,
                    color: Colors.white,
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            playerName.toUpperCase(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E22AA),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(context, stats.pace.round().toString(), "PAC"),
                  _buildStat(context, stats.dribbling.round().toString(), "DRI"),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(context, stats.shooting.round().toString(), "SHO"),
                  _buildStat(context, stats.juggles.round().toString(), "JUG"),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(context, stats.passing.round().toString(), "PAS"),
                  _buildStat(context, stats.first_touch.round().toString(), "TCH"),
                ],
              ),
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
                color: Colors.grey[700],
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
            playerName.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E22AA),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        // Top 3 Stats
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(context, stats.pace.round().toString(), "PAC"),
              _buildStat(context, stats.dribbling.round().toString(), "DRI"),
              _buildStat(context, stats.shooting.round().toString(), "SHO"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E22AA),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E22AA),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 90) return const Color(0xFFFF5252); // Red/Bronze
    if (rating >= 80) return const Color(0xFFFFD700); // Gold
    if (rating >= 70) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }
  
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$month/$day/$year $hour:$minute';
  }
} 