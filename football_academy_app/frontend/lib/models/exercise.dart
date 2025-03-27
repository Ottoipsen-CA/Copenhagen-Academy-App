class Exercise {
  final String? id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String? videoUrl;
  final String? imageUrl;
  final int durationMinutes;
  final List<String>? equipment;
  final List<String>? skills;
  final String? createdBy;
  final DateTime? createdAt;
  final bool isFavorite;

  Exercise({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.videoUrl,
    this.imageUrl,
    required this.durationMinutes,
    this.equipment,
    this.skills,
    this.createdBy,
    this.createdAt,
    this.isFavorite = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      videoUrl: json['videoUrl'],
      imageUrl: json['imageUrl'],
      durationMinutes: json['durationMinutes'],
      equipment: json['equipment'] != null
          ? List<String>.from(json['equipment'])
          : null,
      skills:
          json['skills'] != null ? List<String>.from(json['skills']) : null,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'durationMinutes': durationMinutes,
      'equipment': equipment,
      'skills': skills,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  Exercise copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    String? videoUrl,
    String? imageUrl,
    int? durationMinutes,
    List<String>? equipment,
    List<String>? skills,
    String? createdBy,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return Exercise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      equipment: equipment ?? this.equipment,
      skills: skills ?? this.skills,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
} 