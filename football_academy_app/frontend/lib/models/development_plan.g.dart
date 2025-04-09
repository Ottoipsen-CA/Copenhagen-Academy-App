// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'development_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevelopmentPlan _$DevelopmentPlanFromJson(Map<String, dynamic> json) =>
    DevelopmentPlan(
      id: (json['id'] as num?)?.toInt(),
      playerId: (json['playerId'] as num).toInt(),
      title: json['title'] as String,
      trainingSessions: (json['trainingSessions'] as List<dynamic>)
          .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      focusAreas: (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => FocusArea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      longTermGoals: json['longTermGoals'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$DevelopmentPlanToJson(DevelopmentPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'playerId': instance.playerId,
      'title': instance.title,
      'trainingSessions': instance.trainingSessions,
      'focusAreas': instance.focusAreas,
      'longTermGoals': instance.longTermGoals,
      'notes': instance.notes,
    };

FocusArea _$FocusAreaFromJson(Map<String, dynamic> json) => FocusArea(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: (json['priority'] as num).toInt(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$FocusAreaToJson(FocusArea instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'targetDate': instance.targetDate.toIso8601String(),
      'isCompleted': instance.isCompleted,
    };

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) =>
    TrainingSession(
      sessionId: (json['session_id'] as num?)?.toInt(),
      planId: (json['plan_id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      weekday: (json['weekday'] as num).toInt(),
      startTime: json['start_time'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      preEvaluation: json['pre_evaluation'] == null
          ? null
          : SessionEvaluation.fromJson(
              json['pre_evaluation'] as Map<String, dynamic>),
      postEvaluation: json['post_evaluation'] == null
          ? null
          : SessionEvaluation.fromJson(
              json['post_evaluation'] as Map<String, dynamic>),
      isCompleted: json['is_completed'] as bool? ?? false,
    );

Map<String, dynamic> _$TrainingSessionToJson(TrainingSession instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'plan_id': instance.planId,
      'title': instance.title,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'weekday': instance.weekday,
      'start_time': instance.startTime,
      'duration_minutes': instance.durationMinutes,
      'pre_evaluation': instance.preEvaluation,
      'post_evaluation': instance.postEvaluation,
      'is_completed': instance.isCompleted,
    };

SessionEvaluation _$SessionEvaluationFromJson(Map<String, dynamic> json) =>
    SessionEvaluation(
      evaluationId: (json['evaluation_id'] as num?)?.toInt(),
      sessionId: (json['session_id'] as num).toInt(),
      notes: json['notes'] as String,
      rating: (json['rating'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SessionEvaluationToJson(SessionEvaluation instance) =>
    <String, dynamic>{
      'evaluation_id': instance.evaluationId,
      'session_id': instance.sessionId,
      'notes': instance.notes,
      'rating': instance.rating,
      'created_at': instance.createdAt.toIso8601String(),
    };
