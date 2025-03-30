class PlayerTest {
  final int? id;
  final int? playerId;
  final DateTime? testDate;
  
  // Test values
  final int? passingTest;
  final double? sprintTest;
  final int? firstTouchTest;
  final int? shootingTest;
  final int? jugglingTest;
  final double? dribblingTest;
  
  // Calculated ratings
  final int? passingRating;
  final int? paceRating;
  final int? firstTouchRating;
  final int? shootingRating;
  final int? jugglingRating;
  final int? dribblingRating;
  
  PlayerTest({
    this.id,
    this.playerId,
    this.testDate,
    this.passingTest,
    this.sprintTest,
    this.firstTouchTest,
    this.shootingTest,
    this.jugglingTest,
    this.dribblingTest,
    this.passingRating,
    this.paceRating,
    this.firstTouchRating,
    this.shootingRating,
    this.jugglingRating,
    this.dribblingRating,
  });
  
  factory PlayerTest.fromJson(Map<String, dynamic> json) {
    return PlayerTest(
      id: json['id'],
      playerId: json['player_id'],
      testDate: json['test_date'] != null ? DateTime.parse(json['test_date']) : null,
      passingTest: json['passing_test'],
      sprintTest: json['sprint_test']?.toDouble(),
      firstTouchTest: json['first_touch_test'],
      shootingTest: json['shooting_test'],
      jugglingTest: json['juggling_test'],
      dribblingTest: json['dribbling_test']?.toDouble(),
      passingRating: json['passing_rating'],
      paceRating: json['pace_rating'],
      firstTouchRating: json['first_touch_rating'],
      shootingRating: json['shooting_rating'],
      jugglingRating: json['juggling_rating'],
      dribblingRating: json['dribbling_rating'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (testDate != null) 'test_date': testDate!.toIso8601String(),
      if (passingTest != null) 'passing_test': passingTest,
      if (sprintTest != null) 'sprint_test': sprintTest,
      if (firstTouchTest != null) 'first_touch_test': firstTouchTest,
      if (shootingTest != null) 'shooting_test': shootingTest,
      if (jugglingTest != null) 'juggling_test': jugglingTest,
      if (dribblingTest != null) 'dribbling_test': dribblingTest,
    };
  }
} 