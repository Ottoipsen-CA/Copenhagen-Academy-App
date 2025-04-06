class User {
  final int? id;
  final String email;
  final String fullName;
  final String? position;
  final String? currentClub;
  final DateTime? dateOfBirth;
  final bool isActive;
  final bool isCoach;
  final bool isCaptain;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.email,
    required this.fullName,
    this.position,
    this.currentClub,
    this.dateOfBirth,
    this.isActive = true,
    this.isCoach = false,
    this.isCaptain = false,
    this.role = "player",
    this.createdAt,
    this.lastLogin,
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
      isCaptain: json['is_captain'] ?? false,
      role: json['role'] ?? 'player',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
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
      'is_captain': isCaptain,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
} 