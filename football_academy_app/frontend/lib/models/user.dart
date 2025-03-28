class User {
  final String? id;
  final String email;
  final String fullName;
  final String position;
  final String playerLevel;
  final String? biography;
  final String? club;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? country;
  final String? city;

  User({
    this.id,
    required this.email,
    required this.fullName,
    required this.position,
    required this.playerLevel,
    this.biography,
    this.club,
    this.dateOfBirth,
    this.phoneNumber,
    this.profileImageUrl,
    this.country,
    this.city,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      position: json['position'] ?? 'Forward',
      playerLevel: json['player_level'] ?? json['playerLevel'] ?? 'Beginner',
      biography: json['biography'],
      club: json['club'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      country: json['country'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'position': position,
      'player_level': playerLevel,
      'biography': biography,
      'club': club,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'country': country,
      'city': city,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? position,
    String? playerLevel,
    String? biography,
    String? club,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? profileImageUrl,
    String? country,
    String? city,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
      playerLevel: playerLevel ?? this.playerLevel,
      biography: biography ?? this.biography,
      club: club ?? this.club,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      country: country ?? this.country,
      city: city ?? this.city,
    );
  }
} 