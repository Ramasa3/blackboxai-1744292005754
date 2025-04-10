class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final UserRole role;
  final DateTime createdAt;
  final SubscriptionStatus subscriptionStatus;
  final List<String> favorites;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    required this.role,
    required this.createdAt,
    required this.subscriptionStatus,
    required this.favorites,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profileImage: json['profile_image'] as String?,
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['subscription_status'],
        orElse: () => SubscriptionStatus.none,
      ),
      favorites: List<String>.from(json['favorites'] as List),
      preferences: json['preferences'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image': profileImage,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'subscription_status': subscriptionStatus.toString().split('.').last,
      'favorites': favorites,
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImage,
    UserRole? role,
    DateTime? createdAt,
    SubscriptionStatus? subscriptionStatus,
    List<String>? favorites,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      favorites: favorites ?? this.favorites,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, role: $role, subscriptionStatus: $subscriptionStatus)';
  }
}

enum UserRole {
  admin,
  user,
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  none,
}
