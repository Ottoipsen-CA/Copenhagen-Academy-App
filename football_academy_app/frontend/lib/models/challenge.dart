import 'package:flutter/foundation.dart';

enum ChallengeCategory {
  passing,
  shooting,
  dribbling,
  fitness,
  defense,
  goalkeeping,
  tactical,
  weekly,
  wallTouches
}

extension ChallengeCategoryExtension on ChallengeCategory {
  String get displayName {
    switch (this) {
      case ChallengeCategory.passing:
        return 'Passing';
      case ChallengeCategory.shooting:
        return 'Shooting';
      case ChallengeCategory.dribbling:
        return 'Dribbling';
      case ChallengeCategory.fitness:
        return 'Fitness';
      case ChallengeCategory.defense:
        return 'Defense';
      case ChallengeCategory.goalkeeping:
        return 'Goalkeeping';
      case ChallengeCategory.tactical:
        return 'Tactical';
      case ChallengeCategory.weekly:
        return 'Weekly Challenge';
      case ChallengeCategory.wallTouches:
        return 'Wall Touches';
    }
  }
  
  String get icon {
    switch (this) {
      case ChallengeCategory.passing:
        return 'assets/icons/passing.png';
      case ChallengeCategory.shooting:
        return 'assets/icons/shooting.png';
      case ChallengeCategory.dribbling:
        return 'assets/icons/dribbling.png';
      case ChallengeCategory.fitness:
        return 'assets/icons/fitness.png';
      case ChallengeCategory.defense:
        return 'assets/icons/defense.png';
      case ChallengeCategory.goalkeeping:
        return 'assets/icons/goalkeeping.png';
      case ChallengeCategory.tactical:
        return 'assets/icons/tactical.png';
      case ChallengeCategory.weekly:
        return 'assets/icons/weekly.png';
      case ChallengeCategory.wallTouches:
        return 'assets/icons/wall_touches.png';
    }
  }
}

enum ChallengeStatus {
  locked,
  available,
  inProgress,
  completed
}

extension ChallengeStatusExtension on ChallengeStatus {
  String get apiValue {
    switch (this) {
      case ChallengeStatus.locked:
        return 'LOCKED';
      case ChallengeStatus.available:
        return 'AVAILABLE';
      case ChallengeStatus.inProgress:
        return 'IN_PROGRESS';
      case ChallengeStatus.completed:
        return 'COMPLETED';
    }
  }
  
  static ChallengeStatus fromApiValue(String? value) {
    if (value == null) return ChallengeStatus.locked;
    
    switch (value.toUpperCase()) {
      case 'AVAILABLE':
        return ChallengeStatus.available;
      case 'COMPLETED':
        return ChallengeStatus.completed;
      case 'IN_PROGRESS':
        return ChallengeStatus.inProgress;
      case 'LOCKED':
      default:
        return ChallengeStatus.locked;
    }
  }
}

@immutable
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final int level;
  final double targetValue;
  final String unit;
  final DateTime? deadline;
  final bool isWeekly;
  final List<String>? tips;
  final String? videoUrl;
  final String? imageUrl;
  final int xpReward;
  final bool isActive;
  final String timeRemaining;
  final int participantCount;
  final List<ChallengeSubmission> leaderboard;
  final ChallengeSubmission? userSubmission;
  final ChallengeStatus status;
  final DateTime? optedInAt;
  final DateTime? completedAt;
  final double? userValue;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.targetValue,
    required this.unit,
    required this.xpReward,
    this.deadline,
    this.isWeekly = false,
    this.tips,
    this.videoUrl,
    this.imageUrl,
    this.isActive = true,
    this.timeRemaining = '',
    this.participantCount = 0,
    this.leaderboard = const [],
    this.userSubmission,
    this.status = ChallengeStatus.locked,
    this.optedInAt,
    this.completedAt,
    this.userValue,
  });
  
  factory Challenge.fromJson(Map<String, dynamic> json) {
    // Handle category conversion
    ChallengeCategory categoryValue;
    try {
      final categoryStr = json['category']?.toString().toLowerCase();
      switch (categoryStr) {
        case 'passing': categoryValue = ChallengeCategory.passing; break;
        case 'shooting': categoryValue = ChallengeCategory.shooting; break;
        case 'dribbling': categoryValue = ChallengeCategory.dribbling; break;
        case 'fitness': categoryValue = ChallengeCategory.fitness; break;
        case 'defense': categoryValue = ChallengeCategory.defense; break;
        case 'goalkeeping': categoryValue = ChallengeCategory.goalkeeping; break;
        case 'tactical': categoryValue = ChallengeCategory.tactical; break;
        case 'weekly': categoryValue = ChallengeCategory.weekly; break;
        case 'wall_touches': categoryValue = ChallengeCategory.wallTouches; break;
        default: categoryValue = ChallengeCategory.passing; break;
      }
    } catch (e) {
      categoryValue = ChallengeCategory.passing;
    }
    
    // Parse target value as double (API may send it as int or double)
    double targetValueDouble;
    try {
      targetValueDouble = json['target_value'] is int 
          ? (json['target_value'] as int).toDouble() 
          : json['target_value']?.toDouble() ?? 0.0;
    } catch (e) {
      targetValueDouble = 0.0;
    }
    
    // Parse status
    final statusValue = ChallengeStatusExtension.fromApiValue(json['status']);
    
    return Challenge(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: categoryValue,
      level: json['level'] ?? 1,
      targetValue: targetValueDouble,
      unit: json['unit'] ?? 'count',
      xpReward: json['xp_reward'] ?? 100,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isWeekly: json['is_weekly'] ?? false,
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      videoUrl: json['video_url'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      timeRemaining: json['time_remaining'] ?? '',
      participantCount: json['participant_count'] ?? 0,
      leaderboard: json['leaderboard'] != null 
          ? (json['leaderboard'] as List).map((e) => ChallengeSubmission.fromJson(e)).toList()
          : const [],
      userSubmission: json['user_submission'] != null 
          ? ChallengeSubmission.fromJson(json['user_submission'])
          : null,
      status: statusValue,
      optedInAt: json['opted_in_at'] != null ? DateTime.parse(json['opted_in_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      userValue: json['user_value']?.toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'level': level,
      'target_value': targetValue,
      'unit': unit,
      'xp_reward': xpReward,
      'deadline': deadline?.toIso8601String(),
      'is_weekly': isWeekly,
      'tips': tips,
      'video_url': videoUrl,
      'image_url': imageUrl,
      'is_active': isActive,
      'time_remaining': timeRemaining,
      'participant_count': participantCount,
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      'user_submission': userSubmission?.toJson(),
      'status': status.apiValue,
      'opted_in_at': optedInAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user_value': userValue,
    };
  }

  String formatMetric(double value) {
    return '$value $unit';
  }
  
  // Create a copy of this challenge with updated fields
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    int? level,
    double? targetValue,
    String? unit,
    DateTime? deadline,
    bool? isWeekly,
    List<String>? tips,
    String? videoUrl,
    String? imageUrl,
    int? xpReward,
    bool? isActive,
    String? timeRemaining,
    int? participantCount,
    List<ChallengeSubmission>? leaderboard,
    ChallengeSubmission? userSubmission,
    ChallengeStatus? status,
    DateTime? optedInAt,
    DateTime? completedAt,
    double? userValue,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      isWeekly: isWeekly ?? this.isWeekly,
      tips: tips ?? this.tips,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      xpReward: xpReward ?? this.xpReward,
      isActive: isActive ?? this.isActive,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      participantCount: participantCount ?? this.participantCount,
      leaderboard: leaderboard ?? this.leaderboard,
      userSubmission: userSubmission ?? this.userSubmission,
      status: status ?? this.status,
      optedInAt: optedInAt ?? this.optedInAt,
      completedAt: completedAt ?? this.completedAt,
      userValue: userValue ?? this.userValue,
    );
  }
}

@immutable
class UserChallenge {
  final String challengeId;
  final ChallengeStatus status;
  final int currentValue;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ChallengeAttempt>? attempts;
  final int rank;

  const UserChallenge({
    required this.challengeId,
    required this.status,
    this.currentValue = 0,
    required this.startedAt,
    this.completedAt,
    this.attempts,
    this.rank = 0,
  });
  
  double get progressPercentage {
    return 0.0;
  }
  
  UserChallenge copyWith({
    String? challengeId,
    ChallengeStatus? status,
    int? currentValue,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ChallengeAttempt>? attempts,
    int? rank,
  }) {
    return UserChallenge(
      challengeId: challengeId ?? this.challengeId,
      status: status ?? this.status,
      currentValue: currentValue ?? this.currentValue,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      attempts: attempts ?? this.attempts,
      rank: rank ?? this.rank,
    );
  }
  
  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      challengeId: json['challenge_id'].toString(),
      status: ChallengeStatusExtension.fromApiValue(json['status']),
      currentValue: json['current_value'] ?? 0,
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      attempts: json['attempts'] != null
          ? (json['attempts'] as List).map((e) => ChallengeAttempt.fromJson(e)).toList()
          : null,
      rank: json['rank'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'status': status.apiValue,
      'current_value': currentValue,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'attempts': attempts?.map((e) => e.toJson()).toList(),
      'rank': rank,
    };
  }
}

@immutable
class ChallengeAttempt {
  final DateTime timestamp;
  final int value;
  final String? notes;

  const ChallengeAttempt({
    required this.timestamp,
    required this.value,
    this.notes,
  });
  
  factory ChallengeAttempt.fromJson(Map<String, dynamic> json) {
    return ChallengeAttempt(
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'],
      notes: json['notes'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'notes': notes,
    };
  }
}

@immutable
class ChallengeSubmission {
  final String userId;
  final String userName;
  final String? userImageUrl;
  final double value;
  final DateTime submittedAt;
  final int rank;

  const ChallengeSubmission({
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.value,
    required this.submittedAt,
    required this.rank,
  });

  factory ChallengeSubmission.fromJson(Map<String, dynamic> json) {
    return ChallengeSubmission(
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? '',
      userImageUrl: json['user_image_url'],
      value: (json['value'] is int) 
          ? (json['value'] as int).toDouble() 
          : (json['value'] ?? 0.0).toDouble(),
      submittedAt: DateTime.parse(json['submitted_at'] ?? DateTime.now().toIso8601String()),
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_image_url': userImageUrl,
      'value': value,
      'submitted_at': submittedAt.toIso8601String(),
      'rank': rank,
    };
  }
} 