class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final String? handle;
  final String? bio;
  final String? location;
  final int points;
  final int followingCount;
  final int reviewsCount;
  final int wishlistCount;
  final int ordersCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.handle,
    this.bio,
    this.location,
    this.points = 0,
    this.followingCount = 0,
    this.reviewsCount = 0,
    this.wishlistCount = 0,
    this.ordersCount = 0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      avatar: map['avatar'],
      handle: map['handle'],
      bio: map['bio'],
      location: map['location'],
      points: map['points'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      reviewsCount: map['reviewsCount'] ?? 0,
      wishlistCount: map['wishlistCount'] ?? 0,
      ordersCount: map['ordersCount'] ?? 0,
    );
  }
}
