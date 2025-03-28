import 'package:flutter/foundation.dart';

@immutable
class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String challengeType; // e.g., 'juggling', 'shooting', 'passing'
  final String metric; // e.g., 'count', 'time', 'distance'
  final String? imageUrl;
  final int participantCount;
  final List<ChallengeSubmission> leaderboard;
  final ChallengeSubmission? userSubmission;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.challengeType,
    required this.metric,
    this.imageUrl,
    required this.participantCount,
    required this.leaderboard,
    this.userSubmission,
  });

  String get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return 'Ended';
    }
    
    final difference = endDate.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} ${hours > 0 ? ', $hours hour${hours > 1 ? 's' : ''}' : ''} left';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} left';
    } else {
      final minutes = difference.inMinutes % 60;
      return '$minutes minute${minutes > 1 ? 's' : ''} left';
    }
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  double get progressPercentage {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    
    final totalDuration = endDate.difference(startDate).inSeconds;
    final elapsed = now.difference(startDate).inSeconds;
    
    return elapsed / totalDuration;
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    List<ChallengeSubmission> leaderboard = [];
    if (json['leaderboard'] != null) {
      leaderboard = (json['leaderboard'] as List)
          .map((item) => ChallengeSubmission.fromJson(item))
          .toList();
    }
    
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      challengeType: json['challengeType'],
      metric: json['metric'],
      imageUrl: json['imageUrl'],
      participantCount: json['participantCount'] ?? 0,
      leaderboard: leaderboard,
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
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'challengeType': challengeType,
      'metric': metric,
      'imageUrl': imageUrl,
      'participantCount': participantCount,
      'leaderboard': leaderboard.map((submission) => submission.toJson()).toList(),
      'userSubmission': userSubmission?.toJson(),
    };
  }

  String formatMetric(double value) {
    switch (metric) {
      case 'time':
        final minutes = (value / 60).floor();
        final seconds = (value % 60).floor();
        return '$minutes:${seconds.toString().padLeft(2, '0')}';
      case 'distance':
        if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(2)} km';
        } else {
          return '${value.toStringAsFixed(0)} m';
        }
      case 'count':
        return value.toStringAsFixed(0);
      case 'points':
        return value.toStringAsFixed(0);
      default:
        return value.toString();
    }
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
      userId: json['userId'],
      userName: json['userName'],
      userImageUrl: json['userImageUrl'],
      value: json['value'].toDouble(),
      submittedAt: DateTime.parse(json['submittedAt']),
      rank: json['rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'value': value,
      'submittedAt': submittedAt.toIso8601String(),
      'rank': rank,
    };
  }
} 