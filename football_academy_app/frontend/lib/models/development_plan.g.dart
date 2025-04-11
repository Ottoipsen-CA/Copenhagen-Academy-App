// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'development_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevelopmentPlan _$DevelopmentPlanFromJson(Map<String, dynamic> json) =>
    DevelopmentPlan(
      planId: (json['id'] as num?)?.toInt(),
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      longTermGoals: json['long_term_goals'] as String,
      notes: json['notes'] as String?,
      focusAreas: (json['focus_areas'] as List<dynamic>?)
              ?.map((e) => FocusArea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DevelopmentPlanToJson(DevelopmentPlan instance) =>
    <String, dynamic>{
      'id': instance.planId,
      'user_id': instance.userId,
      'title': instance.title,
      'long_term_goals': instance.longTermGoals,
      'notes': instance.notes,
      'focus_areas': instance.focusAreas,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };

FocusArea _$FocusAreaFromJson(Map<String, dynamic> json) => FocusArea(
      focusAreaId: (json['id'] as num?)?.toInt(),
      developmentPlanId: (json['development_plan_id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      priority: (json['priority'] as num).toInt(),
      targetDate: DateTime.parse(json['target_date'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      status: json['status'] as String? ?? 'in_progress',
    );

Map<String, dynamic> _$FocusAreaToJson(FocusArea instance) => <String, dynamic>{
      'id': instance.focusAreaId,
      'development_plan_id': instance.developmentPlanId,
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'target_date': '${instance.targetDate.year}-${instance.targetDate.month.toString().padLeft(2, '0')}-${instance.targetDate.day.toString().padLeft(2, '0')}',
      'is_completed': instance.isCompleted,
      'status': instance.status,
    };
