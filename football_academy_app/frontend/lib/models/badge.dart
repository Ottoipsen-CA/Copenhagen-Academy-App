import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class UserBadge {
  final String id;
  final String name;
  final String description;
  final String category; // e.g., 'skills', 'challenges', 'consistency'
  final BadgeRarity rarity;
  final bool isEarned;
  final DateTime? earnedDate;
  final IconData badgeIcon;
  final Color badgeColor;
  final String? imageUrl;
  final String? iconName;
  final BadgeRequirement requirement;

  const UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.isEarned,
    this.earnedDate,
    required this.badgeIcon,
    required this.badgeColor,
    this.imageUrl,
    this.iconName,
    required this.requirement,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    final iconName = json['iconName'] ?? 'trophy';
    final rarityValue = rarityFromString(json['rarity']);
    
    return UserBadge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      rarity: rarityValue,
      isEarned: json['isEarned'] ?? false,
      earnedDate: json['earnedDate'] != null ? DateTime.parse(json['earnedDate']) : null,
      badgeIcon: getIconForType(iconName),
      badgeColor: getColorForRarity(rarityValue),
      imageUrl: json['imageUrl'],
      iconName: iconName,
      requirement: BadgeRequirement.fromJson(json['requirement']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'rarity': rarityToString(rarity),
      'isEarned': isEarned,
      'earnedDate': earnedDate?.toIso8601String(),
      'iconName': iconName ?? getTypeForIcon(badgeIcon),
      'imageUrl': imageUrl,
      'requirement': requirement.toJson(),
    };
  }

  static BadgeRarity rarityFromString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return BadgeRarity.common;
      case 'uncommon':
        return BadgeRarity.uncommon;
      case 'rare':
        return BadgeRarity.rare;
      case 'epic':
        return BadgeRarity.epic;
      case 'legendary':
        return BadgeRarity.legendary;
      default:
        return BadgeRarity.common;
    }
  }

  static String rarityToString(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return 'common';
      case BadgeRarity.uncommon:
        return 'uncommon';
      case BadgeRarity.rare:
        return 'rare';
      case BadgeRarity.epic:
        return 'epic';
      case BadgeRarity.legendary:
        return 'legendary';
    }
  }

  static IconData getIconForType(String type) {
    switch (type) {
      case 'trophy':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      case 'crown':
        return Icons.king_bed;
      case 'medal':
        return Icons.military_tech;
      case 'achievement':
        return Icons.workspace_premium;
      case 'streak':
        return Icons.local_fire_department;
      case 'skills':
        return Icons.sports_soccer;
      case 'team':
        return Icons.people;
      case 'leadership':
        return Icons.escalator_warning;
      case 'dribbling':
        return Icons.directions_run;
      case 'shooting':
        return Icons.sports_soccer;
      case 'passing':
        return Icons.swap_calls;
      default:
        return Icons.emoji_events;
    }
  }

  static String getTypeForIcon(IconData icon) {
    if (icon == Icons.emoji_events) return 'trophy';
    if (icon == Icons.star) return 'star';
    if (icon == Icons.king_bed) return 'crown';
    if (icon == Icons.military_tech) return 'medal';
    if (icon == Icons.workspace_premium) return 'achievement';
    if (icon == Icons.local_fire_department) return 'streak';
    if (icon == Icons.sports_soccer) return 'skills';
    if (icon == Icons.people) return 'team';
    if (icon == Icons.escalator_warning) return 'leadership';
    if (icon == Icons.directions_run) return 'dribbling';
    if (icon == Icons.swap_calls) return 'passing';
    return 'trophy';
  }

  static Color getColorForRarity(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.green;
      case BadgeRarity.uncommon:
        return Colors.blue;
      case BadgeRarity.rare:
        return Colors.purple;
      case BadgeRarity.epic:
        return Colors.orange;
      case BadgeRarity.legendary:
        return Colors.red;
    }
  }
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class BadgeRequirement {
  final String type;
  final int targetValue;
  final int currentValue;
  
  const BadgeRequirement({
    required this.type,
    required this.targetValue,
    required this.currentValue,
  });
  
  double get progress => currentValue / targetValue;
  
  factory BadgeRequirement.fromJson(Map<String, dynamic> json) {
    return BadgeRequirement(
      type: json['type'],
      targetValue: json['targetValue'],
      currentValue: json['currentValue'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'targetValue': targetValue,
      'currentValue': currentValue,
    };
  }
} 