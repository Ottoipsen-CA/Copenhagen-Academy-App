import 'package:intl/intl.dart';

class TrainingSchedule {
  final int? id;
  final int userId;
  final int? developmentPlanId;
  final int weekNumber;
  final int year;
  final String title;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TrainingSession> trainingSessions;

  TrainingSchedule({
    this.id,
    required this.userId,
    this.developmentPlanId,
    required this.weekNumber,
    required this.year,
    required this.title,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.trainingSessions = const [],
  });

  factory TrainingSchedule.fromJson(Map<String, dynamic> json) {
    return TrainingSchedule(
      id: json['id'],
      userId: json['user_id'],
      developmentPlanId: json['development_plan_id'],
      weekNumber: json['week_number'],
      year: json['year'],
      title: json['title'],
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      trainingSessions: json['training_sessions'] != null
          ? List<TrainingSession>.from(
              json['training_sessions'].map(
                (session) => TrainingSession.fromJson(session),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'week_number': weekNumber,
      'year': year,
      'title': title,
    };

    if (developmentPlanId != null) {
      data['development_plan_id'] = developmentPlanId;
    }
    
    if (notes != null) {
      data['notes'] = notes;
    }

    return data;
  }
}

class TrainingSession {
  final int? id;
  final int scheduleId;
  final int dayOfWeek;
  final DateTime sessionDate;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final String? location;
  final int? focusAreaId;
  final bool hasReflection;
  final String? reflectionText;
  final DateTime? reflectionAddedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TrainingSession({
    this.id,
    required this.scheduleId,
    required this.dayOfWeek,
    required this.sessionDate,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.focusAreaId,
    this.hasReflection = false,
    this.reflectionText,
    this.reflectionAddedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'],
      scheduleId: json['schedule_id'],
      dayOfWeek: json['day_of_week'],
      sessionDate: DateTime.parse(json['session_date']),
      title: json['title'],
      description: json['description'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      location: json['location'],
      focusAreaId: json['focus_area_id'],
      hasReflection: json['has_reflection'] ?? false,
      reflectionText: json['reflection_text'],
      reflectionAddedAt: json['reflection_added_at'] != null 
          ? DateTime.parse(json['reflection_added_at']) 
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    
    final Map<String, dynamic> data = {
      'schedule_id': scheduleId,
      'day_of_week': dayOfWeek,
      'session_date': dateFormat.format(sessionDate),
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
    };

    if (description != null) {
      data['description'] = description;
    }
    
    if (location != null) {
      data['location'] = location;
    }
    
    if (focusAreaId != null) {
      data['focus_area_id'] = focusAreaId;
    }

    return data;
  }

  String get formattedTime => '$startTime - $endTime';
  
  String get formattedDate {
    final DateFormat formatter = DateFormat('d. MMMM');
    return formatter.format(sessionDate);
  }
  
  String getDayName() {
    final List<String> dayNames = ['Mandag', 'Tirsdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lørdag', 'Søndag'];
    return dayNames[dayOfWeek - 1];
  }
}

class TrainingReflection {
  final String reflectionText;

  TrainingReflection({
    required this.reflectionText,
  });

  Map<String, dynamic> toJson() {
    return {
      'reflection_text': reflectionText,
    };
  }
} 