class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin' or 'kasir'
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }
}