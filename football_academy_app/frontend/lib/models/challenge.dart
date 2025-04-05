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

@immutable
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final int level;
  final int targetValue;
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
  });
  
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: ChallengeCategory.values.firstWhere(
        (e) => e.toString() == 'ChallengeCategory.${json['category']}',
      ),
      level: json['level'],
      targetValue: json['targetValue'],
      unit: json['unit'],
      xpReward: json['xpReward'] ?? 100,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isWeekly: json['isWeekly'] ?? false,
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      timeRemaining: json['timeRemaining'] ?? '',
      participantCount: json['participantCount'] ?? 0,
      leaderboard: json['leaderboard'] != null 
          ? (json['leaderboard'] as List).map((e) => ChallengeSubmission.fromJson(e)).toList()
          : [],
      userSubmission: json['userSubmission'] != null 
          ? ChallengeSubmission.fromJson(json['userSubmission'])
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'level': level,
      'targetValue': targetValue,
      'unit': unit,
      'xpReward': xpReward,
      'deadline': deadline?.toIso8601String(),
      'isWeekly': isWeekly,
      'tips': tips,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'timeRemaining': timeRemaining,
      'participantCount': participantCount,
      'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      'userSubmission': userSubmission?.toJson(),
    };
  }

  String formatMetric(double value) {
    return '$value $unit';
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
    ChallengeStatus statusValue;
    
    try {
      // For backward compatibility - try the old format first
      statusValue = ChallengeStatus.values.firstWhere(
        (e) => e.toString() == 'ChallengeStatus.${json['status']}',
        orElse: () {
          // Try parsing directly from the lowercase string value
          final statusString = json['status']?.toString().toLowerCase();
          switch (statusString) {
            case 'available': return ChallengeStatus.available;
            case 'completed': return ChallengeStatus.completed;
            case 'in_progress': return ChallengeStatus.inProgress;
            case 'locked': 
            default: return ChallengeStatus.locked;
          }
        }
      );
    } catch (e) {
      print('Error parsing status: ${json['status']} - defaulting to locked');
      statusValue = ChallengeStatus.locked;
    }
    
    return UserChallenge(
      challengeId: json['challengeId'],
      status: statusValue,
      currentValue: json['currentValue'] ?? 0,
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      attempts: json['attempts'] != null
          ? (json['attempts'] as List).map((e) => ChallengeAttempt.fromJson(e)).toList()
          : null,
      rank: json['rank'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'status': status.toString().split('.').last,
      'currentValue': currentValue,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
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
      userName: json['user_name'],
      userImageUrl: json['user_image_url'],
      value: json['value'].toDouble(),
      submittedAt: DateTime.parse(json['submitted_at']),
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