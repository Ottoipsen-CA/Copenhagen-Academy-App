class User {
  final int? id;
  final String email;
  final String fullName;
  final String? position;
  final String? currentClub;
  final DateTime? dateOfBirth;
  final bool isActive;
  final bool isCoach;

  User({
    this.id,
    required this.email,
    required this.fullName,
    this.position,
    this.currentClub,
    this.dateOfBirth,
    this.isActive = true,
    this.isCoach = false,
  });

  String get firstName => fullName.split(' ').first;
  String get lastName => fullName.split(' ').length > 1 
      ? fullName.split(' ').skip(1).join(' ') 
      : '';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      position: json['position'],
      currentClub: json['current_club'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      isActive: json['is_active'] ?? true,
      isCoach: json['is_coach'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'position': position,
      'current_club': currentClub,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'is_active': isActive,
      'is_coach': isCoach,
    };
  }
} 