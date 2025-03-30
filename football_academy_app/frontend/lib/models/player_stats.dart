class PlayerStats {
  final int? id;
  final String playerId;
  final double pace;
  final double shooting;
  final double passing;
  final double dribbling;
  final double juggles;
  final double first_touch;
  final double overallRating;
  final DateTime? lastUpdated;

  PlayerStats({
    this.id,
    required this.playerId,
    this.pace = 80,
    this.shooting = 79,
    this.passing = 76,
    this.dribbling = 81,
    this.juggles = 65,
    this.first_touch = 72,
    this.overallRating = 83,
    this.lastUpdated,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      id: json['id'],
      playerId: json['player_id'].toString(),
      pace: json['pace']?.toDouble() ?? 80,
      shooting: json['shooting']?.toDouble() ?? 79,
      passing: json['passing']?.toDouble() ?? 76,
      dribbling: json['dribbling']?.toDouble() ?? 81,
      juggles: json['juggles']?.toDouble() ?? 65,
      first_touch: json['first_touch']?.toDouble() ?? 72,
      overallRating: json['overall_rating']?.toDouble() ?? 83,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'pace': pace,
      'shooting': shooting,
      'passing': passing,
      'dribbling': dribbling,
      'juggles': juggles,
      'first_touch': first_touch,
      'overall_rating': overallRating,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
} 