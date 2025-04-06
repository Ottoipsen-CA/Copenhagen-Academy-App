import 'package:flutter/material.dart';
import '../models/player_stats.dart';

class FifaPlayerCard extends StatelessWidget {
  final String playerName;
  final String position;
  final PlayerStats stats;
  final int rating;
  final CardType cardType;
  
  const FifaPlayerCard({
    super.key,
    required this.playerName,
    required this.position,
    required this.stats,
    required this.rating,
    this.cardType = CardType.normal,
  });

  // Get card color based on rating and type
  List<Color> _getCardColors() {
    // Use a gradient from bright to darker for better text visibility
    return const [
      Color(0xFF1C54B2), // Brighter blue at top
      Color(0xFF0B2265), // Darker blue at bottom
    ];
  }
  
  // Get position-specific icon and color
  IconData _getPositionIcon() {
    // Group positions into categories
    if (position == 'GK') {
      return Icons.sports_handball;
    } else if (['CB', 'RB', 'LB'].contains(position)) {
      return Icons.shield;
    } else if (['CDM', 'CM', 'CAM', 'LW', 'RW'].contains(position)) {
      return Icons.swap_horiz;
    } else {
      // Default to striker for ST or unknown positions
      return Icons.sports_soccer;
    }
  }
  
  Color _getPositionColor() {
    if (position == 'GK') {
      return Colors.amber;
    } else if (['CB', 'RB', 'LB'].contains(position)) {
      return Colors.lightGreen;
    } else if (['CDM', 'CM', 'CAM', 'LW', 'RW'].contains(position)) {
      return Colors.cyanAccent;
    } else {
      // Strikers and unknown positions
      return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColors = _getCardColors();
    final positionIcon = _getPositionIcon();
    final positionColor = _getPositionColor();
    
    // Skill colors matching the performance section
    final Map<String, Color> skillColors = {
      'Pace': const Color(0xFF02D39A),
      'Shooting': const Color(0xFFFFD700),
      'Passing': const Color(0xFF00ACF3),
      'Dribbling': const Color(0xFFBE008C),
      'Juggles': const Color(0xFF3875B9),
      'First Touch': const Color(0xFFD48A29),
    };
    
    return Container(
      width: 220,
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Card background - gradient from lighter to darker for better visibility
          ClipRRect(
            borderRadius: BorderRadius.circular(9), // Slightly smaller to account for border
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: cardColors,
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Top section with rating and position
                Row(
                  children: [
                    // Rating box
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 3.0,
                                color: Colors.black,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // Position
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        position,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Position icon instead of player image
                Expanded(
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: positionColor.withOpacity(0.2),
                        border: Border.all(
                          color: positionColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: positionColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        positionIcon,
                        size: 60,
                        color: positionColor,
                      ),
                    ),
                  ),
                ),
                
                // Player name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      playerName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Stats - updated to match performance section names and icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Pace',
                      stats.pace?.toInt() ?? 0,
                      Icons.speed,
                      skillColors['Pace']!,
                    ),
                    _buildStatItem(
                      'Shooting',
                      stats.shooting?.toInt() ?? 0,
                      Icons.sports_soccer,
                      skillColors['Shooting']!,
                    ),
                    _buildStatItem(
                      'Passing',
                      stats.passing?.toInt() ?? 0,
                      Icons.swap_horizontal_circle,
                      skillColors['Passing']!,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Dribbling',
                      stats.dribbling?.toInt() ?? 0,
                      Icons.directions_run,
                      skillColors['Dribbling']!,
                    ),
                    _buildStatItem(
                      'Juggles',
                      stats.juggles?.toInt() ?? 0,
                      Icons.flutter_dash,
                      skillColors['Juggles']!,
                    ),
                    _buildStatItem(
                      'First Touch',
                      stats.firstTouch?.toInt() ?? 0,
                      Icons.touch_app,
                      skillColors['First Touch']!,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Special card indicator - kept this for the card types
          if (cardType != CardType.normal)
            Positioned(
              top: 60,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getCardTypeLabel() {
    switch (cardType) {
      case CardType.icon:
        return 'ICON';
      case CardType.record_breaker:
        return 'RECORD BREAKER';
      case CardType.ones_to_watch:
        return 'ONES TO WATCH';
      case CardType.totw:
        return 'TEAM OF THE WEEK';
      case CardType.toty:
        return 'TEAM OF THE YEAR';
      case CardType.future:
        return 'FUTURE STAR';
      case CardType.hero:
        return 'HERO';
      case CardType.normal:
        return '';
    }
  }
  
  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color: color,
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1, 1),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: TextStyle(
            color: Colors.white,
            backgroundColor: color.withOpacity(0.2),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius:
                 3.0,
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum CardType {
  normal,
  totw,          // Team of the Week
  toty,          // Team of the Year
  future,        // Future Stars 
  hero,          // Hero Card
  icon,          // Icon Card (95+ rating)
  record_breaker, // Record Breaker
  ones_to_watch,  // Ones to Watch
} 