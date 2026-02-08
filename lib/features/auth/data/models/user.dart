class AppUser {
  final String id;
  final String email;
  final String name;
  
  AppUser({
    required this.id,
    required this.email,
    required this.name,
  });
  
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? json['_id'],
      email: json['email'],
      name: json['name'],
    );
  }
}

class AppAuthResponse {
  final AppUser user;
  final String token;
  
  AppAuthResponse({
    required this.user,
    required this.token,
  });
  
  factory AppAuthResponse.fromJson(Map<String, dynamic> json) {
    return AppAuthResponse(
      user: AppUser.fromJson(json['user']),
      token: json['token'],
    );
  }
}

