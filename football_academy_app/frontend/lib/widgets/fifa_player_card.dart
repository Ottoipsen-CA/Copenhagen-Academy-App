import 'package:flutter/material.dart';
import '../models/player_stats.dart';

class FifaPlayerCard extends StatelessWidget {
  final String playerName;
  final String position;
  final PlayerStats stats;
  final int rating;
  final String nationality;
  final String? playerImageUrl;
  final CardType cardType;
  
  const FifaPlayerCard({
    super.key,
    required this.playerName,
    required this.position,
    required this.stats,
    required this.rating,
    this.nationality = '🇦🇺', // Default flag
    this.playerImageUrl,
    this.cardType = CardType.normal,
  });

  // Get card color based on rating and type
  List<Color> _getCardColors() {
    // Special card types first
    switch (cardType) {
      case CardType.totw:
        return const [Color(0xFF3875B9), Color(0xFF173968)]; // Team of the Week
      case CardType.toty:
        return const [Color(0xFF00ACF3), Color(0xFF0571A0)]; // Team of the Year
      case CardType.future:
        return const [Color(0xFFBE008C), Color(0xFF780153)]; // Future Stars
      case CardType.hero:
        return const [Color(0xFFD48A29), Color(0xFF89571A)]; // Hero
      case CardType.normal:
        // Normal cards based on rating
        if (rating >= 85) {
          // Gold card
          return const [
            Color(0xFFFFD700), // Gold top
            Color(0xFFEBC137), // Darker gold bottom
          ];
        } else if (rating >= 75) {
          // Silver card
          return const [
            Color(0xFFE1E1E1), // Silver top
            Color(0xFFAAA9AD), // Darker silver bottom
          ];
        } else {
          // Bronze card
          return const [
            Color(0xFFCD7F32), // Bronze top
            Color(0xFF996515), // Darker bronze bottom
          ];
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColors = _getCardColors();
    
    return Container(
      width: 220,
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card background
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: cardColors,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // Pattern overlay for special cards
          if (cardType != CardType.normal)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.network(
                  'https://i.imgur.com/T5l3zTi.png', // Pattern overlay image URL
                  fit: BoxFit.cover,
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
                      ),
                      child: Center(
                        child: Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // Position
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        position,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Player image
                Expanded(
                  child: Center(
                    child: playerImageUrl != null
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(playerImageUrl!),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white30,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
                
                // Player name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      playerName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatColumn("PAC", stats.pace.toInt()),
                    _buildStatColumn("SHO", stats.shooting.toInt()),
                    _buildStatColumn("PAS", stats.passing.toInt()),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatColumn("DRI", stats.dribbling.toInt()),
                    _buildStatColumn("DEF", stats.defense.toInt()),
                    _buildStatColumn("PHY", stats.physical.toInt()),
                  ],
                ),
              ],
            ),
          ),
          
          // FIFA Logo - top right
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.7),
              ),
              child: const Center(
                child: Text(
                  "FA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // Country flag - bottom right
          Positioned(
            bottom: 60,
            right: 8,
            child: Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.blue.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  nationality,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // Special card indicator
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
                child: Text(
                  _getCardTypeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
  
  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

enum CardType {
  normal,
  totw,    // Team of the Week
  toty,    // Team of the Year
  future,  // Future Stars 
  hero,    // Hero Card
} 