class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'],
        email: json['email'],
        fullName: json['full_name'],
        avatarUrl: json['avatar_url'],
        role: json['role'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'role': role,
      };
}

class AuthResponse {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: AuthUser.fromJson(json['user']),
        accessToken: json['access_token'],
        refreshToken: json['refresh_token'],
      );
}