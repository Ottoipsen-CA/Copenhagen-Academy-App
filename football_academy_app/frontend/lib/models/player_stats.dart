class PlayerStats {
  final int? id;
  final String playerId;
  final double pace;
  final double shooting;
  final double passing;
  final double dribbling;
  final double defense;
  final double physical;
  final double overallRating;
  final DateTime? lastUpdated;

  PlayerStats({
    this.id,
    required this.playerId,
    this.pace = 80,
    this.shooting = 79,
    this.passing = 76,
    this.dribbling = 81,
    this.defense = 49,
    this.physical = 70,
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
      defense: json['defense']?.toDouble() ?? 49,
      physical: json['physical']?.toDouble() ?? 70,
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
      'defense': defense,
      'physical': physical,
      'overall_rating': overallRating,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
} 