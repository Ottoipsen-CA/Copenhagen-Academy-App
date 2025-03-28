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
    this.pace = 50,
    this.shooting = 50,
    this.passing = 50,
    this.dribbling = 50,
    this.defense = 50,
    this.physical = 50,
    this.overallRating = 50,
    this.lastUpdated,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      id: json['id'],
      playerId: json['player_id'].toString(),
      pace: json['pace']?.toDouble() ?? 50,
      shooting: json['shooting']?.toDouble() ?? 50,
      passing: json['passing']?.toDouble() ?? 50,
      dribbling: json['dribbling']?.toDouble() ?? 50,
      defense: json['defense']?.toDouble() ?? 50,
      physical: json['physical']?.toDouble() ?? 50,
      overallRating: json['overall_rating']?.toDouble() ?? 50,
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