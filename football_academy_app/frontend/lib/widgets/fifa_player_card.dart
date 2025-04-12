import 'package:flutter/material.dart';
import '../models/player_stats.dart';

class FifaPlayerCard extends StatelessWidget {
  final String playerName;
  final String position;
  final PlayerStats stats;
  final int rating;
  final CardType cardType;
  final String? profileImageUrl;
  final double? width; // Added width parameter for responsiveness
  
  const FifaPlayerCard({
    super.key,
    required this.playerName,
    required this.position,
    required this.stats,
    required this.rating,
    this.cardType = CardType.normal,
    this.profileImageUrl,
    this.width,
  });

  // Get card color based on rating and type
  List<Color> _getCardColors() {
    // Use a gradient from bright to darker for better text visibility
    // Changed to a gold gradient for rare gold effect
    return const [
      Color(0xFFFDE047), // Lighter Gold/Yellow
      Color(0xFFEAB308), // Medium Gold
      Color(0xFFCA8A04), // Darker Gold
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
    // Make the card responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? (screenWidth < 400 ? screenWidth * 0.8 : 220.0);
    final cardHeight = cardWidth * 1.5; // Maintain aspect ratio
    
    // Scale elements based on card size
    final isSmallCard = cardWidth < 200;
    final fontSize = isSmallCard ? 12.0 : 14.0;
    final ratingSize = isSmallCard ? 20.0 : 24.0;
    final positionSize = isSmallCard ? 14.0 : 16.0;
    final statIconSize = isSmallCard ? 18.0 : 22.0;
    final statFontSize = isSmallCard ? 14.0 : 16.0;
    final imageSizeRatio = isSmallCard ? 0.4 : 0.5; // Image size as percentage of card width
    
    final cardColors = _getCardColors();
    final positionIcon = _getPositionIcon();
    final positionColor = _getPositionColor();
    
    // Check if this is the login page card
    final isLoginCard = playerName == "C. RONALDO";
    

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
      width: cardWidth,
      height: cardHeight,
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
            padding: EdgeInsets.all(cardWidth * 0.04), // Scaled padding
            child: Column(
              children: [
                // Top section with rating and position
                Row(
                  children: [
                    // Rating box
                    Container(
                      width: cardWidth * 0.2, // Scaled rating box
                      height: cardWidth * 0.2,
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ratingSize,
                            fontWeight: FontWeight.bold,
                            shadows: const [
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
                    SizedBox(width: cardWidth * 0.03), // Scaled spacing
                    
                    // Position
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: cardWidth * 0.04,
                        vertical: cardWidth * 0.02,
                      ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: positionSize,
                          fontWeight: FontWeight.bold,
                          shadows: const [
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
                
                // Player image or position icon
                Expanded(
                  child: Center(
                    child: Container(
                      width: cardWidth * (isLoginCard ? 0.6 : imageSizeRatio),
                      height: cardWidth * (isLoginCard ? 0.6 : imageSizeRatio),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLoginCard ? Colors.red.withOpacity(0.7) : positionColor.withOpacity(0.2),
                        border: Border.all(
                          color: isLoginCard ? Colors.red : positionColor,
                          width: 2,
                        ),
                        image: profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profileImageUrl == null || profileImageUrl!.isEmpty
                          ? Center(
                              child: Icon(
                                positionIcon,
                                size: cardWidth * (isLoginCard ? 0.3 : 0.2),
                                color: isLoginCard ? Colors.white : positionColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                
                // Player name - hide for login card
                if (!isLoginCard)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: cardWidth * 0.03),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: const [
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
                
                // Add spacing only if player name is shown
                if (!isLoginCard)
                  SizedBox(height: cardWidth * 0.03), // Scaled spacing
                
                // Stats - updated to match performance section names and icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Pace',
                      stats.pace?.toInt() ?? 0,
                      Icons.speed,
                      skillColors['Pace']!,
                      statIconSize,
                      statFontSize,
                    ),
                    _buildStatItem(
                      'Shooting',
                      stats.shooting?.toInt() ?? 0,
                      Icons.sports_soccer,
                      skillColors['Shooting']!,
                      statIconSize,
                      statFontSize,
                    ),
                    _buildStatItem(
                      'Passing',
                      stats.passing?.toInt() ?? 0,
                      Icons.swap_horizontal_circle,
                      skillColors['Passing']!,
                      statIconSize,
                      statFontSize,
                    ),
                  ],
                ),
                SizedBox(height: cardWidth * 0.02), // Scaled spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Dribbling',
                      stats.dribbling?.toInt() ?? 0,
                      Icons.directions_run,
                      skillColors['Dribbling']!,
                      statIconSize,
                      statFontSize,
                    ),
                    _buildStatItem(
                      'Juggles',
                      stats.juggles?.toInt() ?? 0,
                      Icons.flutter_dash,
                      skillColors['Juggles']!,
                      statIconSize,
                      statFontSize,
                    ),
                    _buildStatItem(
                      'First Touch',
                      stats.firstTouch?.toInt() ?? 0,
                      Icons.touch_app,
                      skillColors['First Touch']!,
                      statIconSize,
                      statFontSize,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Special card indicator - don't show for login card
          if (cardType != CardType.normal && !isLoginCard)
            Positioned(
              top: cardHeight * 0.18,
              left: cardWidth * 0.05,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: cardWidth * 0.03,
                  vertical: cardWidth * 0.015,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black.withOpacity(0.8),
                ),
                child: Text(
                  _getCardTypeLabel(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize * 0.8,
                    fontWeight: FontWeight.bold,
                  ),
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
  
  Widget _buildStatItem(String label, int value, IconData icon, Color color, double iconSize, double fontSize) {
    return Column(
      children: [
        Icon(
          icon,
          size: iconSize,
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
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 3.0,
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