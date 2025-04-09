import 'package:json_annotation/json_annotation.dart';

part 'development_plan.g.dart';

@JsonSerializable()
class DevelopmentPlan {
  final int? id;
  final int playerId;
  final String title;
  final List<TrainingSession> trainingSessions;
  final List<FocusArea> focusAreas;
  final String? longTermGoals;
  final String? notes;

  DevelopmentPlan({
    this.id,
    required this.playerId,
    required this.title,
    required this.trainingSessions,
    this.focusAreas = const [],
    this.longTermGoals,
    this.notes,
  });

  factory DevelopmentPlan.fromJson(Map<String, dynamic> json) => _$DevelopmentPlanFromJson(json);
  Map<String, dynamic> toJson() => _$DevelopmentPlanToJson(this);
}

@JsonSerializable()
class FocusArea {
  final int? id;
  final String title;
  final String description;
  final int priority; // 1-5, with 5 being highest priority
  final DateTime targetDate;
  final bool isCompleted;

  FocusArea({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.targetDate,
    this.isCompleted = false,
  });

  factory FocusArea.fromJson(Map<String, dynamic> json) => _$FocusAreaFromJson(json);
  Map<String, dynamic> toJson() => _$FocusAreaToJson(this);
}

@JsonSerializable()
class TrainingSession {
  @JsonKey(name: 'session_id')
  final int? sessionId;
  @JsonKey(name: 'plan_id')
  final int planId;
  final String title;
  final String? description;
  final DateTime date;
  final int weekday;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @JsonKey(name: 'pre_evaluation')
  SessionEvaluation? preEvaluation;
  @JsonKey(name: 'post_evaluation')
  SessionEvaluation? postEvaluation;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;

  TrainingSession({
    this.sessionId,
    required this.planId,
    required this.title,
    this.description,
    required this.date,
    required this.weekday,
    required this.startTime,
    required this.durationMinutes,
    this.preEvaluation,
    this.postEvaluation,
    this.isCompleted = false,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) => _$TrainingSessionFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingSessionToJson(this);
}

@JsonSerializable()
class SessionEvaluation {
  @JsonKey(name: 'evaluation_id')
  final int? evaluationId;
  @JsonKey(name: 'session_id')
  final int sessionId;
  final String notes;
  final int rating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  SessionEvaluation({
    this.evaluationId,
    required this.sessionId,
    required this.notes,
    required this.rating,
    required this.createdAt,
  });

  factory SessionEvaluation.fromJson(Map<String, dynamic> json) => _$SessionEvaluationFromJson(json);
  Map<String, dynamic> toJson() => _$SessionEvaluationToJson(this);
} 