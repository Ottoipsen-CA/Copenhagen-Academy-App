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
  
  // Record flags
  final bool? isPassingRecord;
  final bool? isSprintRecord;
  final bool? isFirstTouchRecord;
  final bool? isShootingRecord;
  final bool? isJugglingRecord;
  final bool? isDribblingRecord;
  
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
    this.isPassingRecord,
    this.isSprintRecord,
    this.isFirstTouchRecord, 
    this.isShootingRecord,
    this.isJugglingRecord,
    this.isDribblingRecord,
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
      isPassingRecord: json['is_passing_record'],
      isSprintRecord: json['is_sprint_record'],
      isFirstTouchRecord: json['is_first_touch_record'],
      isShootingRecord: json['is_shooting_record'],
      isJugglingRecord: json['is_juggling_record'],
      isDribblingRecord: json['is_dribbling_record'],
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
  
  // Check if this test broke any records based on player position
  bool brokeAnyRecord(String position) {
    // Get max values based on position from Playertest document
    Map<String, dynamic> maxResults = {};
    
    if (position == 'ST' || position == 'CF' || position == 'LW' || position == 'RW') {
      // Striker values
      maxResults = {
        'passing': 40,
        'sprint': 1.9, // Lower is better
        'firstTouch': 35,
        'shooting': 14,
        'juggling': 150,
        'dribbling': 12, // Lower is better
      };
    } else if (position == 'CM' || position == 'CDM' || position == 'CAM' || position == 'LM' || position == 'RM') {
      // Midfielder values
      maxResults = {
        'passing': 45,
        'sprint': 1.9, // Lower is better
        'firstTouch': 40,
        'shooting': 12,
        'juggling': 150,
        'dribbling': 11, // Lower is better
      };
    } else {
      // Defender values
      maxResults = {
        'passing': 40,
        'sprint': 1.9, // Lower is better
        'firstTouch': 35,
        'shooting': 11,
        'juggling': 150,
        'dribbling': 12, // Lower is better
      };
    }
    
    // Check if any test broke a record
    bool brokeRecord = false;
    
    // For tests where higher is better
    if (passingTest != null && passingTest! > maxResults['passing']) {
      brokeRecord = true;
    }
    
    if (firstTouchTest != null && firstTouchTest! > maxResults['firstTouch']) {
      brokeRecord = true;
    }
    
    if (shootingTest != null && shootingTest! > maxResults['shooting']) {
      brokeRecord = true;
    }
    
    if (jugglingTest != null && jugglingTest! > maxResults['juggling']) {
      brokeRecord = true;
    }
    
    // For tests where lower is better
    if (sprintTest != null && sprintTest! < maxResults['sprint']) {
      brokeRecord = true;
    }
    
    if (dribblingTest != null && dribblingTest! < maxResults['dribbling']) {
      brokeRecord = true;
    }
    
    return brokeRecord;
  }
} 