class Reel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String videoUrl;
  final String description;
  final int likes;
  final int comments;
  final String? emoji;
  final List<String> likesList; // List of user IDs who liked

  Reel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.videoUrl,
    required this.description,
    required this.likes,
    required this.comments,
    this.emoji,
    this.likesList = const <String>[],
  });

  factory Reel.fromMap(Map<String, dynamic> map) {
    // Backend populates 'seller' with { _id, name, avatar }
    final sellerObj = map['seller'] is Map ? map['seller'] : null;
    final sellerId =
        sellerObj != null ? (sellerObj['_id'] ?? '') : (map['sellerId'] ?? '');
    final sellerName = sellerObj != null
        ? (sellerObj['name'] ?? '')
        : (map['sellerName'] ?? '');

    // likes from backend is an array of object IDs
    int likesCount = 0;
    if (map['likes'] is List) {
      likesCount = (map['likes'] as List).length;
    } else if (map['likes'] is int) {
      likesCount = map['likes'];
    }

    int commentsCount = 0;
    if (map['comments'] is List) {
      commentsCount = (map['comments'] as List).length;
    } else if (map['comments'] is int) {
      commentsCount = map['comments'];
    }

    return Reel(
      id: map['_id'] ?? '',
      sellerId: sellerId,
      sellerName: sellerName,
      videoUrl: map['videoUrl'] ?? '',
      description: map['caption'] ?? map['description'] ?? '',
      likes: likesCount,
      comments: commentsCount,
      emoji: map['emoji'] ?? (sellerObj != null ? sellerObj['avatar'] : null),
      likesList: map['likes'] is List 
          ? (map['likes'] as List).map((e) => e.toString()).toList() 
          : <String>[],
    );
  }
}
