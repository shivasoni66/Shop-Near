class Reel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String videoUrl;
  final String description;
  final int likes;
  final int comments;
  final String? emoji;

  Reel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.videoUrl,
    required this.description,
    required this.likes,
    required this.comments,
    this.emoji,
  });

  factory Reel.fromMap(Map<String, dynamic> map) {
    return Reel(
      id: map['_id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      description: map['description'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      emoji: map['emoji'],
    );
  }
}
