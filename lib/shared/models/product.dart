class Product {
  final String id;
  final String name;
  final String shopName;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewsCount;
  final int soldCount;
  final int stockCount;
  final String imagePlaceholder; // Emoji
  final List<String> tags;
  final String description;
  final String category;

  const Product({
    required this.id,
    required this.name,
    required this.shopName,
    required this.price,
    this.oldPrice,
    required this.rating,
    this.reviewsCount = 0,
    this.soldCount = 0,
    this.stockCount = 0,
    required this.imagePlaceholder,
    this.tags = const [],
    this.description = '',
    this.category = 'All',
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    try {
      return Product(
        id: (map['_id'] ?? map['id'] ?? '').toString(),
        name: map['name']?.toString() ?? 'Unnamed Product',
        shopName: (map['seller'] is Map ? map['seller']['name'] : null) ?? map['shopName']?.toString() ?? 'Local Seller',
        price: double.tryParse((map['price'] ?? 0).toString()) ?? 0.0,
        oldPrice: map['oldPrice'] != null ? double.tryParse(map['oldPrice'].toString()) : null,
        rating: double.tryParse((map['rating'] ?? 0).toString()) ?? 0.0,
        reviewsCount: int.tryParse((map['reviewsCount'] ?? 0).toString()) ?? 0,
        soldCount: int.tryParse((map['soldCount'] ?? 0).toString()) ?? 0,
        stockCount: int.tryParse((map['stockCount'] ?? map['stock'] ?? 0).toString()) ?? 0,
        imagePlaceholder: (map['images'] is List && (map['images'] as List).isNotEmpty) 
          ? map['images'][0].toString() 
          : (map['imagePlaceholder']?.toString() ?? '📦'),
        tags: map['tags'] is List ? List<String>.from(map['tags'].map((e) => e.toString())) : const [],
        description: map['description']?.toString() ?? '',
        category: map['category']?.toString() ?? 'All',
      );
    } catch (e) {
      print('Error parsing product: $e');
      // Return a fallback product so the whole list doesn't fail
      return const Product(
        id: 'error',
        name: 'Error loading product',
        shopName: 'Unknown',
        price: 0,
        rating: 0,
        imagePlaceholder: '⚠️',
      );
    }
  }
}
