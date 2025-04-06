class PlayerTest {
  final int? id;
  final int? playerId;
  final DateTime? testDate;
  final String? position;
  
  // Raw test values
  final double? pace;
  final double? shooting;
  final double? passing;
  final double? dribbling;
  final double? juggles;
  final double? firstTouch;
  
  // Calculated ratings (1-99 scale)
  final int? paceRating;
  final int? shootingRating;
  final int? passingRating;
  final int? dribblingRating;
  final int? jugglesRating;
  final int? firstTouchRating;
  final int? overallRating;
  
  // Legacy test values for backward compatibility 
  final int? passingTest;
  final double? sprintTest;
  final int? firstTouchTest;
  final int? shootingTest;
  final int? jugglingTest;
  final double? dribblingTest;
  
  // Fields to track personal records
  final bool? isPassingRecord;
  final bool? isSprintRecord;
  final bool? isFirstTouchRecord;
  final bool? isShootingRecord;
  final bool? isJugglingRecord;
  final bool? isDribblingRecord;
  
  final String? notes;
  final int? recordedBy;
  
  PlayerTest({
    this.id,
    this.playerId,
    this.testDate,
    this.position,
    // Raw values
    this.pace,
    this.shooting,
    this.passing,
    this.dribbling,
    this.juggles,
    this.firstTouch,
    // Ratings
    this.paceRating,
    this.shootingRating,
    this.passingRating,
    this.dribblingRating,
    this.jugglesRating,
    this.firstTouchRating,
    this.overallRating,
    // Legacy fields
    this.passingTest,
    this.sprintTest,
    this.firstTouchTest,
    this.shootingTest,
    this.jugglingTest,
    this.dribblingTest,
    // Records
    this.isPassingRecord,
    this.isSprintRecord,
    this.isFirstTouchRecord,
    this.isShootingRecord,
    this.isJugglingRecord,
    this.isDribblingRecord,
    // Additional info
    this.notes,
    this.recordedBy,
  });
  
  factory PlayerTest.fromJson(Map<String, dynamic> json) {
    return PlayerTest(
      id: json['id'],
      playerId: json['player_id'],
      testDate: json['test_date'] != null ? DateTime.parse(json['test_date']) : null,
      position: json['position'],
      // Raw values
      pace: json['pace'] != null ? double.parse(json['pace'].toString()) : null,
      shooting: json['shooting'] != null ? double.parse(json['shooting'].toString()) : null, 
      passing: json['passing'] != null ? double.parse(json['passing'].toString()) : null,
      dribbling: json['dribbling'] != null ? double.parse(json['dribbling'].toString()) : null,
      juggles: json['juggles'] != null ? double.parse(json['juggles'].toString()) : null,
      firstTouch: json['first_touch'] != null ? double.parse(json['first_touch'].toString()) : null,
      // Ratings
      paceRating: json['pace_rating'],
      shootingRating: json['shooting_rating'],
      passingRating: json['passing_rating'],
      dribblingRating: json['dribbling_rating'],
      jugglesRating: json['juggles_rating'],
      firstTouchRating: json['first_touch_rating'],
      overallRating: json['overall_rating'],
      // Legacy fields
      passingTest: json['passing_test'],
      sprintTest: json['sprint_test'] != null ? double.parse(json['sprint_test'].toString()) : null,
      firstTouchTest: json['first_touch_test'],
      shootingTest: json['shooting_test'],
      jugglingTest: json['juggling_test'],
      dribblingTest: json['dribbling_test'] != null ? double.parse(json['dribbling_test'].toString()) : null,
      // Records
      isPassingRecord: json['is_passing_record'],
      isSprintRecord: json['is_sprint_record'],
      isFirstTouchRecord: json['is_first_touch_record'],
      isShootingRecord: json['is_shooting_record'],
      isJugglingRecord: json['is_juggling_record'],
      isDribblingRecord: json['is_dribbling_record'],
      // Additional info
      notes: json['notes'],
      recordedBy: json['recorded_by'],
    );
  }
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      // Use new fields if they exist, otherwise fall back to legacy fields
      'pace': pace,
      'shooting': shooting,
      'passing': passing,
      'dribbling': dribbling, 
      'juggles': juggles,
      'first_touch': firstTouch,
      // Include ratings if they exist
      'pace_rating': paceRating,
      'shooting_rating': shootingRating,
      'passing_rating': passingRating,
      'dribbling_rating': dribblingRating, 
      'juggles_rating': jugglesRating,
      'first_touch_rating': firstTouchRating,
      'overall_rating': overallRating,
      // Legacy fields for backwards compatibility
      'passing_test': passingTest,
      'sprint_test': sprintTest,
      'first_touch_test': firstTouchTest,
      'shooting_test': shootingTest,
      'juggling_test': jugglingTest,
      'dribbling_test': dribblingTest,
      // Include position and other metadata
      'position': position,
      'test_date': testDate?.toIso8601String(),
      'notes': notes,
      'recorded_by': recordedBy,
    };
    
    // Only include ID if it exists (for updates)
    if (id != null) {
      data['id'] = id;
    }
    
    // Only include player_id if set
    if (playerId != null) {
      data['player_id'] = playerId;
    }
    
    return data;
  }
  
  // Helper method to get overall rating or calculate from component ratings if not available
  int getOverallRating() {
    // Use stored overall if available
    if (overallRating != null) {
      return overallRating!;
    }
    
    // Calculate from component ratings if available
    int count = 0;
    int sum = 0;
    
    if (paceRating != null) { sum += paceRating!; count++; }
    if (shootingRating != null) { sum += shootingRating!; count++; }
    if (passingRating != null) { sum += passingRating!; count++; }
    if (dribblingRating != null) { sum += dribblingRating!; count++; }
    if (jugglesRating != null) { sum += jugglesRating!; count++; }
    if (firstTouchRating != null) { sum += firstTouchRating!; count++; }
    
    if (count > 0) {
      return sum ~/count;
    }
    
    // Fall back to estimating from raw values
    return 50; // Default value if no data available
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