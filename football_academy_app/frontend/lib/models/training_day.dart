class TrainingDay {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingDay({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingDay.fromJson(Map<String, dynamic> json) {
    return TrainingDay(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TrainingDayCreate {
  final String title;
  final String description;
  final DateTime date;

  TrainingDayCreate({
    required this.title,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}

class TrainingDayEntry {
  final int id;
  final int trainingDayId;
  final int userId;
  final String? preSessionNotes;
  final String? postSessionNotes;
  final String attendanceStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TrainingDay? trainingDay;

  TrainingDayEntry({
    required this.id,
    required this.trainingDayId,
    required this.userId,
    this.preSessionNotes,
    this.postSessionNotes,
    required this.attendanceStatus,
    required this.createdAt,
    required this.updatedAt,
    this.trainingDay,
  });

  factory TrainingDayEntry.fromJson(Map<String, dynamic> json) {
    return TrainingDayEntry(
      id: json['id'],
      trainingDayId: json['training_day_id'],
      userId: json['user_id'],
      preSessionNotes: json['pre_session_notes'],
      postSessionNotes: json['post_session_notes'],
      attendanceStatus: json['attendance_status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      trainingDay: json['training_day'] != null 
          ? TrainingDay.fromJson(json['training_day']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'training_day_id': trainingDayId,
      'user_id': userId,
      'pre_session_notes': preSessionNotes,
      'post_session_notes': postSessionNotes,
      'attendance_status': attendanceStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (trainingDay != null) 'training_day': trainingDay!.toJson(),
    };
  }
} 