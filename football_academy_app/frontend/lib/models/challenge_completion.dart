import 'dart:convert';

class ChallengeCompletion {
  final int id;
  final int challengeId;
  final int completionTime;
  final double score;
  final Map<String, dynamic> stats;
  final DateTime completedAt;

  ChallengeCompletion({
    required this.id,
    required this.challengeId,
    required this.completionTime,
    required this.score,
    required this.stats,
    required this.completedAt,
  });

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletion(
      id: json['id'],
      challengeId: json['challenge_id'],
      completionTime: json['completion_time'],
      score: json['score'].toDouble(),
      stats: json['stats'] is String ? jsonDecode(json['stats']) : json['stats'],
      completedAt: DateTime.parse(json['completed_at']),
    );
  }
}

class ChallengeCompletionWithDetails extends ChallengeCompletion {
  final String challengeTitle;
  final String challengeDescription;

  ChallengeCompletionWithDetails({
    required super.id,
    required super.challengeId,
    required super.completionTime,
    required super.score,
    required super.stats,
    required super.completedAt,
    required this.challengeTitle,
    required this.challengeDescription,
  });

  factory ChallengeCompletionWithDetails.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletionWithDetails(
      id: json['id'],
      challengeId: json['challenge_id'],
      completionTime: json['completion_time'],
      score: json['score'].toDouble(),
      stats: json['stats'] is String ? jsonDecode(json['stats']) : json['stats'],
      completedAt: DateTime.parse(json['completed_at']),
      challengeTitle: json['challenge_title'],
      challengeDescription: json['challenge_description'],
    );
  }
} 