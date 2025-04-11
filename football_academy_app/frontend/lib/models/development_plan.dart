import 'package:json_annotation/json_annotation.dart';

part 'development_plan.g.dart';

@JsonSerializable()
class DevelopmentPlan {
  @JsonKey(name: 'id')
  final int? planId;
  
  @JsonKey(name: 'user_id')
  final int userId;
  
  final String title;
  
  @JsonKey(name: 'long_term_goals')
  final String longTermGoals;
  
  final String? notes;
  
  @JsonKey(name: 'focus_areas', defaultValue: [])
  final List<FocusArea> focusAreas;

  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime? updatedAt;

  DevelopmentPlan({
    this.planId,
    required this.userId,
    required this.title,
    required this.longTermGoals,
    this.notes,
    this.focusAreas = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DevelopmentPlan.fromJson(Map<String, dynamic> json) => _$DevelopmentPlanFromJson(json);
  Map<String, dynamic> toJson() => _$DevelopmentPlanToJson(this);

  DevelopmentPlan copyWith({
    int? planId,
    int? userId,
    String? title,
    String? longTermGoals,
    String? notes,
    List<FocusArea>? focusAreas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DevelopmentPlan(
      planId: planId ?? this.planId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      longTermGoals: longTermGoals ?? this.longTermGoals,
      notes: notes ?? this.notes,
      focusAreas: focusAreas ?? this.focusAreas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class FocusArea {
  @JsonKey(name: 'id')
  final int? focusAreaId;

  @JsonKey(name: 'development_plan_id')
  final int developmentPlanId;
  
  final String title;
  final String description;
  final int priority;
  
  @JsonKey(name: 'target_date')
  final DateTime targetDate;
  
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  
  @JsonKey(name: 'status')
  final String status;

  FocusArea({
    this.focusAreaId,
    required this.developmentPlanId,
    required this.title,
    required this.description,
    required this.priority,
    required this.targetDate,
    this.isCompleted = false,
    this.status = 'in_progress',
  });

  factory FocusArea.fromJson(Map<String, dynamic> json) => _$FocusAreaFromJson(json);
  Map<String, dynamic> toJson() => _$FocusAreaToJson(this);

  FocusArea copyWith({
    int? focusAreaId,
    int? developmentPlanId,
    String? title,
    String? description,
    int? priority,
    DateTime? targetDate,
    bool? isCompleted,
    String? status,
  }) {
    return FocusArea(
      focusAreaId: focusAreaId ?? this.focusAreaId,
      developmentPlanId: developmentPlanId ?? this.developmentPlanId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
    );
  }
} 