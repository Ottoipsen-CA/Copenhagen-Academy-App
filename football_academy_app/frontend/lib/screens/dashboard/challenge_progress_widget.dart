import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/challenge.dart';
import '../../models/badge.dart';
import '../../services/challenge_progress_service.dart';
import '../badges/badges_page.dart';
import '../challenges/challenge_detail_page.dart';
import '../challenges/challenge_completion_page.dart';

class ChallengeProgressWidget extends StatefulWidget {
  const ChallengeProgressWidget({Key? key}) : super(key: key);

  @override
  State<ChallengeProgressWidget> createState() => _ChallengeProgressWidgetState();
}

class _ChallengeProgressWidgetState extends State<ChallengeProgressWidget> {
  bool _isLoading = true;
  List<BadgeWithChallenge> _badges = [];
  Map<String, dynamic> _stats = {};
  List<ChallengeCompletionWithDetails> _recentCompletions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = Provider.of<ChallengeProgressService>(context, listen: false);
      
      // Get user badges
      final badges = await service.getUserBadges();
      
      // Get challenge statistics
      final stats = await service.getChallengeStatistics();
      
      // Get user completions
      final completions = await service.getUserCompletions();
      
      // Sort completions by date (newest first)
      completions.sort((a, b) => b.completionDate.compareTo(a.completionDate));
      
      if (mounted) {
        setState(() {
          _badges = badges;
          _stats = stats;
          _recentCompletions = completions.take(3).toList(); // Take most recent 3
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading challenge progress: $e')),
        );
      }
    }
  }

  // Convert our BadgeWithChallenge to UserBadge for compatibility
  List<UserBadge> _convertToUserBadges() {
    return _badges.map((badge) {
      // Convert category to a badge icon and color
      IconData iconData = _getCategoryIcon(badge.challenge.category);
      Color color = _getCategoryColor(badge.challenge.category);
      
      return UserBadge(
        id: badge.id.toString(),
        name: badge.name,
        description: badge.description,
        category: badge.challenge.category,
        rarity: UserBadge.rarityFromString('rare'), // Default to rare
        isEarned: true, // All badges here are earned
        earnedDate: badge.earnedAt,
        badgeIcon: iconData,
        badgeColor: color,
        imageUrl: badge.imageUrl,
        iconName: UserBadge.getTypeForIcon(iconData),
        requirement: const BadgeRequirement(
          type: 'challenge',
          targetValue: 1,
          currentValue: 1,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Challenge Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full badge page with converted badges
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BadgesPage(badges: _convertToUserBadges()),
                      ),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Badge summary
            _buildBadgeSummary(),
            
            const SizedBox(height: 24),
            
            // Recent completions
            const Text(
              'Recent Completions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            _buildRecentCompletions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeSummary() {
    if (_badges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No badges earned yet. Complete challenges to earn badges!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges Earned: ${_badges.length}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Badge showcase
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _badges.length > 5 ? 5 : _badges.length,
            itemBuilder: (context, index) {
              final badge = _badges[index];
              final color = _getCategoryColor(badge.challenge.category);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withOpacity(0.3),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: color,
                        child: Icon(
                          _getCategoryIcon(badge.challenge.category),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCompletions() {
    if (_recentCompletions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No challenges completed yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentCompletions.length,
      itemBuilder: (context, index) {
        final completion = _recentCompletions[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor(completion.challenge.category),
            child: Icon(
              _getCategoryIcon(completion.challenge.category),
              color: Colors.white,
            ),
          ),
          title: Text(completion.challenge.name),
          subtitle: Text(
            'Score: ${completion.score.toStringAsFixed(1)} | Time: ${_formatTime(completion.completionTime)}',
          ),
          trailing: Text(
            '${_formatDate(completion.completionDate)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          onTap: () {
            // Navigate to our challenge completion page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChallengeCompletionPage(
                  challengeId: completion.challenge.id,
                  challengeName: completion.challenge.name,
                  challengeCategory: completion.challenge.category,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'passing':
        return Colors.blue;
      case 'shooting':
        return Colors.red;
      case 'dribbling':
        return Colors.green;
      case 'fitness':
        return Colors.orange;
      case 'defense':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'passing':
        return Icons.sports_soccer;
      case 'shooting':
        return Icons.sports_soccer;
      case 'dribbling':
        return Icons.directions_run;
      case 'fitness':
        return Icons.fitness_center;
      case 'defense':
        return Icons.shield;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 