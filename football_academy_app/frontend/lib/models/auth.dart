class AuthResponse {
  final String accessToken;
  final String tokenType;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': email, // FastAPI OAuth expects 'username'
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String? position;
  final String? currentClub;
  final DateTime? dateOfBirth;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.position,
    this.currentClub,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'full_name': fullName,
      'position': position,
      'current_club': currentClub,
      'date_of_birth': dateOfBirth?.toIso8601String(),
    };
  }
} 