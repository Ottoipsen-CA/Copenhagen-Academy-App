import 'package:flutter/material.dart';
import '../../models/badge.dart';

class BadgesPage extends StatefulWidget {
  final List<UserBadge> badges;

  const BadgesPage({Key? key, required this.badges}) : super(key: key);

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Badges'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0057),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFA500),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Earned'),
            Tab(text: 'Locked'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0057), // Dark blue/purple
              Color(0xFF1C006C), // Mid purple
              Color(0xFF3D007A), // Lighter purple
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // All badges
            _buildBadgeGrid(widget.badges),
            
            // Earned badges
            _buildBadgeGrid(
              widget.badges.where((badge) => badge.isEarned).toList(),
            ),
            
            // Locked badges
            _buildBadgeGrid(
              widget.badges.where((badge) => !badge.isEarned).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<UserBadge> badges) {
    if (badges.isEmpty) {
      return Center(
        child: Text(
          'No badges in this category',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return _buildBadgeCard(badges[index]);
      },
    );
  }

  Widget _buildBadgeCard(UserBadge badge) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: badge.isEarned
              ? badge.color.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showBadgeDetails(badge),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                badge.isEarned
                    ? badge.color.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                badge.isEarned
                    ? badge.color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isEarned
                      ? badge.color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: badge.isEarned
                        ? badge.color
                        : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: badge.isEarned
                    ? Icon(
                        badge.icon,
                        color: badge.color,
                        size: 40,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            badge.icon,
                            color: Colors.white.withOpacity(0.3),
                            size: 40,
                          ),
                          const Icon(
                            Icons.lock,
                            color: Colors.white54,
                            size: 24,
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Badge name
              Text(
                badge.name,
                style: TextStyle(
                  color: badge.isEarned
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Badge category
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badge.isEarned
                      ? badge.color.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: badge.isEarned
                        ? badge.color.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  badge.category.toUpperCase(),
                  style: TextStyle(
                    color: badge.isEarned
                        ? badge.color
                        : Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              if (badge.isEarned)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatEarnedDate(badge.earnedDate!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(UserBadge badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C006C),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.isEarned
                      ? badge.color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: badge.isEarned
                        ? badge.color
                        : Colors.white.withOpacity(0.1),
                    width: 3,
                  ),
                ),
                child: badge.isEarned
                    ? Icon(
                        badge.icon,
                        color: badge.color,
                        size: 60,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            badge.icon,
                            color: Colors.white.withOpacity(0.3),
                            size: 60,
                          ),
                          const Icon(
                            Icons.lock,
                            color: Colors.white54,
                            size: 30,
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Badge name
              Text(
                badge.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Badge rarity and category
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badge.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: badge.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _formatRarity(badge.rarity),
                      style: TextStyle(
                        color: badge.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      badge.category.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Badge description
              Text(
                badge.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Earned date or progress
              if (badge.isEarned)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Badge Earned',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatEarnedDate(badge.earnedDate!),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildProgressBar(badge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(UserBadge badge) {
    final progress = badge.requirement.progress;
    final currentValue = badge.requirement.currentValue;
    final targetValue = badge.requirement.targetValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '$currentValue/$targetValue',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(badge.color),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        Text(
          _getRequirementText(badge.requirement),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatEarnedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${difference} days ago';
    }
  }

  String _formatRarity(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return 'COMMON';
      case BadgeRarity.uncommon:
        return 'UNCOMMON';
      case BadgeRarity.rare:
        return 'RARE';
      case BadgeRarity.epic:
        return 'EPIC';
      case BadgeRarity.legendary:
        return 'LEGENDARY';
    }
  }

  String _getRequirementText(BadgeRequirement requirement) {
    switch (requirement.type) {
      case 'challenge_completions':
        return 'Complete ${requirement.targetValue} challenges';
      case 'challenge_wins':
        return 'Win ${requirement.targetValue} weekly challenges';
      case 'login_streak':
        return 'Log in for ${requirement.targetValue} consecutive days';
      case 'skill_level':
        return 'Reach ${requirement.targetValue} in skill level';
      default:
        return requirement.type;
    }
  }
} 