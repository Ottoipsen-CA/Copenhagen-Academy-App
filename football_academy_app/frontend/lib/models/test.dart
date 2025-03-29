class Test {
  final int id;
  final String title;
  final String testType;
  final double pointsScale;
  final DateTime createdAt;
  final DateTime updatedAt;

  Test({
    required this.id,
    required this.title,
    required this.testType,
    required this.pointsScale,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      id: json['id'],
      title: json['title'],
      testType: json['test_type'],
      pointsScale: json['points_scale'].toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'test_type': testType,
      'points_scale': pointsScale,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TestEntry {
  final int id;
  final int testId;
  final int userId;
  final double score;
  final DateTime takenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Test? test; // Optional test details

  TestEntry({
    required this.id,
    required this.testId,
    required this.userId,
    required this.score,
    required this.takenAt,
    required this.createdAt,
    required this.updatedAt,
    this.test,
  });

  factory TestEntry.fromJson(Map<String, dynamic> json) {
    return TestEntry(
      id: json['id'],
      testId: json['test_id'],
      userId: json['user_id'],
      score: json['score'].toDouble(),
      takenAt: DateTime.parse(json['taken_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      test: json['test'] != null ? Test.fromJson(json['test']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_id': testId,
      'user_id': userId,
      'score': score,
      'taken_at': takenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (test != null) 'test': test!.toJson(),
    };
  }
}

class TestCreate {
  final String title;
  final String testType;
  final double pointsScale;

  TestCreate({
    required this.title,
    required this.testType,
    this.pointsScale = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'test_type': testType,
      'points_scale': pointsScale,
    };
  }
}

class TestEntryCreate {
  final int testId;
  final int userId;
  final double score;
  final String? notes;

  TestEntryCreate({
    required this.testId,
    required this.userId,
    required this.score,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'user_id': userId,
      'score': score,
      'notes': notes,
    };
  }
} 