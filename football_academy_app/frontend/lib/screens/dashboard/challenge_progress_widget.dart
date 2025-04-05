import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/challenge.dart';
import '../../models/badge.dart';
import '../../models/challenge_completion.dart';
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
      
      // Get user completions
      final List<ChallengeCompletionWithDetails> completions = await service.getUserCompletions();
      
      // Sort completions by date (newest first)
      completions.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
      
      if (mounted) {
        setState(() {
          _badges = badges;
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
      // Default to passing category for now
      final category = ChallengeCategory.passing;
      IconData iconData = _getCategoryIcon(category);
      Color color = _getCategoryColor(category);
      
      return UserBadge(
        id: badge.id.toString(),
        name: badge.badgeName,
        description: 'Awarded for completing ${badge.challengeTitle}',
        category: category.toString().split('.').last,
        rarity: UserBadge.rarityFromString('rare'), // Default to rare
        isEarned: true, // All badges here are earned
        earnedDate: DateTime.now(), // Use current date as placeholder
        badgeIcon: iconData,
        badgeColor: color,
        imageUrl: null,
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
              final category = ChallengeCategory.passing;
              final color = _getCategoryColor(category);
              final iconData = _getCategoryIcon(category);
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withAlpha(77), // 0.3 opacity
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: color,
                        child: Icon(
                          iconData,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.badgeName,
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

    return Column(
      children: _recentCompletions.map((completion) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withAlpha(77),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.blue,
            ),
          ),
          title: Text(completion.challengeTitle),
          subtitle: Text(
            'Completed on ${completion.completedAt?.toString().split(' ')[0] ?? ''}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to challenge details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChallengeCompletionPage(
                  challengeId: completion.challengeId,
                  challengeName: completion.challengeTitle,
                  challengeCategory: 'general',
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.passing:
        return Icons.sports_soccer;
      case ChallengeCategory.shooting:
        return Icons.sports_soccer;
      case ChallengeCategory.dribbling:
        return Icons.directions_run;
      case ChallengeCategory.fitness:
        return Icons.fitness_center;
      case ChallengeCategory.defense:
        return Icons.shield;
      case ChallengeCategory.goalkeeping:
        return Icons.sports_soccer;
      case ChallengeCategory.tactical:
        return Icons.psychology;
      case ChallengeCategory.weekly:
        return Icons.emoji_events;
      case ChallengeCategory.wallTouches:
        return Icons.sports_soccer;
    }
  }

  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.passing:
        return Colors.blue;
      case ChallengeCategory.shooting:
        return Colors.red;
      case ChallengeCategory.dribbling:
        return Colors.orange;
      case ChallengeCategory.fitness:
        return Colors.purple;
      case ChallengeCategory.defense:
        return Colors.indigo;
      case ChallengeCategory.goalkeeping:
        return Colors.teal;
      case ChallengeCategory.tactical:
        return Colors.brown;
      case ChallengeCategory.weekly:
        return Colors.amber;
      case ChallengeCategory.wallTouches:
        return Colors.green;
    }
  }
} 