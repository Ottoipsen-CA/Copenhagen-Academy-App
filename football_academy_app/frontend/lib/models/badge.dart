import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class UserBadge {
  final String id;
  final String name;
  final String description;
  final String category; // e.g., 'skills', 'challenges', 'consistency'
  final BadgeRarity rarity;
  final String imageUrl;
  final String iconName;
  final bool isEarned;
  final DateTime? earnedDate;
  final BadgeRequirement requirement;

  const UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.imageUrl,
    required this.iconName,
    this.isEarned = false,
    this.earnedDate,
    required this.requirement,
  });

  Color get color {
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

  IconData get icon {
    // This is a simplification - in a real app, you'd map icon names to IconData
    switch (iconName) {
      case 'juggling':
        return Icons.sports_soccer;
      case 'shooting':
        return Icons.sports_soccer;
      case 'passing':
        return Icons.swap_horiz;
      case 'dribbling':
        return Icons.move_down;
      case 'streak':
        return Icons.local_fire_department;
      case 'trophy':
        return Icons.emoji_events;
      case 'star':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.toString().split('.').last == json['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      imageUrl: json['image_url'],
      iconName: json['icon_name'],
      isEarned: json['is_earned'] ?? false,
      earnedDate: json['earned_date'] != null
          ? DateTime.parse(json['earned_date'])
          : null,
      requirement: BadgeRequirement.fromJson(json['requirement']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'rarity': rarity.toString().split('.').last,
      'image_url': imageUrl,
      'icon_name': iconName,
      'is_earned': isEarned,
      'earned_date': earnedDate?.toIso8601String(),
      'requirement': requirement.toJson(),
    };
  }
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

@immutable
class BadgeRequirement {
  final String type; // e.g., 'challenge_wins', 'skill_level', 'streak'
  final int targetValue;
  final int currentValue;
  final double progress;

  const BadgeRequirement({
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.progress = 0.0,
  });

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