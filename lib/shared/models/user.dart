class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatar;
  final String handle;
  final String bio;
  final String location;
  final String phone;
  final int points;
  final int ordersCount;
  final int followingCount;
  final int reviewsCount;
  final UserSettings settings;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar = '',
    this.handle = '',
    this.bio = '',
    this.location = '',
    this.phone = '',
    this.points = 0,
    this.ordersCount = 0,
    this.followingCount = 0,
    this.reviewsCount = 0,
    UserSettings? settings,
  }) : settings = settings ?? UserSettings();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      avatar: map['avatar'] ?? '',
      handle: map['handle'] ?? '',
      bio: map['bio'] ?? '',
      location: map['location'] ?? '',
      phone: map['phone'] ?? '',
      points: map['points'] ?? 0,
      ordersCount: map['ordersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      reviewsCount: map['reviewsCount'] ?? 0,
      settings: map['settings'] != null
          ? UserSettings.fromMap(map['settings'])
          : UserSettings(),
    );
  }
}

class UserSettings {
  final bool liveSessionAlerts;
  final bool orderUpdates;
  final bool offersDeals;
  final bool chatMessages;
  final bool biometricLogin;
  final bool publicProfile;

  UserSettings({
    this.liveSessionAlerts = true,
    this.orderUpdates = true,
    this.offersDeals = true,
    this.chatMessages = false,
    this.biometricLogin = true,
    this.publicProfile = true,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      liveSessionAlerts: map['liveSessionAlerts'] ?? true,
      orderUpdates: map['orderUpdates'] ?? true,
      offersDeals: map['offersDeals'] ?? true,
      chatMessages: map['chatMessages'] ?? false,
      biometricLogin: map['biometricLogin'] ?? true,
      publicProfile: map['publicProfile'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'liveSessionAlerts': liveSessionAlerts,
      'orderUpdates': orderUpdates,
      'offersDeals': offersDeals,
      'chatMessages': chatMessages,
      'biometricLogin': biometricLogin,
      'publicProfile': publicProfile,
    };
  }

  UserSettings copyWith({
    bool? liveSessionAlerts,
    bool? orderUpdates,
    bool? offersDeals,
    bool? chatMessages,
    bool? biometricLogin,
    bool? publicProfile,
  }) {
    return UserSettings(
      liveSessionAlerts: liveSessionAlerts ?? this.liveSessionAlerts,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      offersDeals: offersDeals ?? this.offersDeals,
      chatMessages: chatMessages ?? this.chatMessages,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      publicProfile: publicProfile ?? this.publicProfile,
    );
  }
}
