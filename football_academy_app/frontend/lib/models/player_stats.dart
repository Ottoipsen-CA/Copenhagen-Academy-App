class PlayerStats {
  final double pace;        // Derived from sprint test
  final double shooting;    // Derived from shooting test
  final double passing;     // Derived from passing test
  final double dribbling;   // Derived from dribbling test
  final double juggles;     // Derived from juggling test
  final double firstTouch;  // Derived from first touch test, renamed to camelCase
  
  // Other stats that might be useful
  final double? overallRating;
  final DateTime? lastUpdated;
  final int? lastTestId;

  PlayerStats({
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.juggles,
    required this.firstTouch,
    this.overallRating,
    this.lastUpdated,
    this.lastTestId,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      pace: (json['pace'] ?? 0).toDouble(),
      shooting: (json['shooting'] ?? 0).toDouble(),
      passing: (json['passing'] ?? 0).toDouble(),
      dribbling: (json['dribbling'] ?? 0).toDouble(),
      juggles: (json['juggles'] ?? 0).toDouble(),
      firstTouch: (json['first_touch'] ?? 0).toDouble(),
      overallRating: json['overall_rating'] != null ? (json['overall_rating']).toDouble() : null,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : null,
      lastTestId: json['last_test_id'],
    );
  }
  
  // Create an empty stats object with zeros
  factory PlayerStats.empty() {
    return PlayerStats(
      pace: 0,
      shooting: 0,
      passing: 0,
      dribbling: 0,
      juggles: 0,
      firstTouch: 0,
    );
  }

  // Convert int fields to double for use in charts/radar
  double get paceAsDouble => pace;
  double get shootingAsDouble => shooting;
  double get passingAsDouble => passing;
  double get dribblingAsDouble => dribbling;
  double get jugglesAsDouble => juggles;
  double get firstTouchAsDouble => firstTouch;

  Map<String, dynamic> toJson() {
    return {
      'pace': pace,
      'shooting': shooting,
      'passing': passing,
      'dribbling': dribbling,
      'juggles': juggles,
      'first_touch': firstTouch,
      'overall_rating': overallRating,
      'last_updated': lastUpdated?.toIso8601String(),
      'last_test_id': lastTestId,
    };
  }
} 