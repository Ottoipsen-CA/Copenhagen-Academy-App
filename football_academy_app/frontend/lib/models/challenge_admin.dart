class ChallengeAdmin {
  final int id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int points;
  final Map<String, dynamic> criteria;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int createdBy;
  final int? badgeId;

  ChallengeAdmin({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.criteria,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdBy,
    this.badgeId,
  });

  factory ChallengeAdmin.fromJson(Map<String, dynamic> json) {
    return ChallengeAdmin(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      points: json['points'],
      criteria: json['criteria'] ?? {},
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'],
      createdBy: json['created_by'],
      badgeId: json['badge_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'points': points,
      'criteria': criteria,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'badge_id': badgeId,
    };
  }

  ChallengeAdmin copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? points,
    Map<String, dynamic>? criteria,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? createdBy,
    int? badgeId,
  }) {
    return ChallengeAdmin(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      criteria: criteria ?? this.criteria,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      badgeId: badgeId ?? this.badgeId,
    );
  }
} 