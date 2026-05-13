class LiveSession {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String category;
  final int viewers;
  final String thumbnailPlaceholder;
  final bool isLive;

  const LiveSession({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.category,
    required this.viewers,
    required this.thumbnailPlaceholder,
    this.isLive = true,
  });

  factory LiveSession.fromMap(Map<String, dynamic> map) {
    // Handle seller field which could be a Map (populated) or a String (ID)
    String sId = '';
    String sName = 'Seller';
    
    if (map['seller'] is Map) {
      sId = map['seller']['_id'] ?? '';
      sName = map['seller']['name'] ?? 'Seller';
    } else if (map['seller'] is String) {
      sId = map['seller'];
    }

    return LiveSession(
      id: map['_id'] ?? map['id'] ?? '',
      sellerId: sId.isNotEmpty ? sId : (map['sellerId'] ?? ''),
      sellerName: sName,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      viewers: map['viewers'] ?? map['viewersCount'] ?? 0,
      thumbnailPlaceholder: map['thumbnailPlaceholder'] ?? '📺',
      isLive: map['isLive'] == true || map['isLive'] == null, 
    );
  }
}
