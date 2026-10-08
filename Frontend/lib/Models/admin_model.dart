// lib/Core/Models/admin_model.dart
// Admin Model for storing admin user data from Strapi

class AdminModel {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? avatar;
  final String userRole; // 'admin', 'manager', 'player'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;

  AdminModel({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatar,
    required this.userRole,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
  });

  // Create from Strapi User response
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      userRole: json['user_role'] ?? 'player',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  // Get initials for avatar
  String get initials {
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'A';
  }

  // Check if user is admin
  bool get isAdmin => userRole == 'admin';
  
  // Check if user is manager
  bool get isManager => userRole == 'manager';
  
  // Check if user is player
  bool get isPlayer => userRole == 'player';
}