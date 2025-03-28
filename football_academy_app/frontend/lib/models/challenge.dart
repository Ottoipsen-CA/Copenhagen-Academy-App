import 'package:flutter/foundation.dart';

enum ChallengeCategory {
  passing,
  shooting,
  dribbling,
  fitness,
  defense,
  goalkeeping,
  tactical,
  weekly
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

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.targetValue,
    required this.unit,
    this.deadline,
    this.isWeekly = false,
    this.tips,
    this.videoUrl,
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
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      isWeekly: json['isWeekly'] ?? false,
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      videoUrl: json['videoUrl'],
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
      'deadline': deadline?.toIso8601String(),
      'isWeekly': isWeekly,
      'tips': tips,
      'videoUrl': videoUrl,
    };
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
      challengeId: json['challengeId'],
      status: ChallengeStatus.values.firstWhere(
        (e) => e.toString() == 'ChallengeStatus.${json['status']}',
      ),
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