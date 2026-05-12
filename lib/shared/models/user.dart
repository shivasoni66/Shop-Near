class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final String? handle;
  final String? bio;
  final String? location;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.handle,
    this.bio,
    this.location,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      avatar: map['avatar'],
      handle: map['handle'],
      bio: map['bio'],
      location: map['location'],
    );
  }
}
