import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'product_providers.dart';
import 'mock_product_providers.dart';

// Dynamic product provider that tries database first, then falls back to enhanced mock data
final dynamicProductDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  try {
    // Try to fetch from real database first
    final productAsync = ref.watch(productDetailProvider(id));
    return productAsync.when(
      data: (product) => product,
      loading: () => throw Exception('Loading...'),
      error: (err, stack) => throw err,
    );
  } catch (e) {
    // If database fails, use enhanced mock data with seller information
    print('Database API failed, using enhanced mock data. Error: $e');
    final mockProductAsync = ref.watch(mockProductDetailProvider(id));
    return mockProductAsync.when(
      data: (mockProduct) => _enhanceProductWithSellerInfo(mockProduct, id),
      loading: () => throw Exception('Loading...'),
      error: (err, stack) => throw err,
    );
  }
});

// Enhanced seller information based on product ID
Product _enhanceProductWithSellerInfo(Product baseProduct, String productId) {
  final sellerInfo = getSellerInfo(productId);
  
  // Use a deterministic emoji based on the product ID hash
  final emojis = ['👗', '👚', '👘', '🧥', '👖', '👠', '👜', '💍', '🌸', '🌺'];
  final emojiIndex = productId.hashCode.abs() % emojis.length;
  final dynamicEmoji = baseProduct.imagePlaceholder == '📦' ? emojis[emojiIndex] : baseProduct.imagePlaceholder;

  return Product(
    id: baseProduct.id,
    name: baseProduct.name,
    shopName: sellerInfo['shopName'],
    price: baseProduct.price,
    oldPrice: baseProduct.oldPrice,
    rating: sellerInfo['rating'],
    reviewsCount: sellerInfo['reviewsCount'],
    soldCount: sellerInfo['soldCount'],
    imagePlaceholder: dynamicEmoji,
    tags: baseProduct.tags,
    description: _enhanceDescription(baseProduct.description, sellerInfo),
    category: baseProduct.category,
  );
}

// Dynamic seller information based on product ID hash for uniqueness
Map<String, dynamic> getSellerInfo(String productId) {
  final shops = [
    {'name': 'Priya Fashion Boutique', 'location': 'Mumbai, Maharashtra', 'verified': true, 'specialty': 'Traditional Sarees'},
    {'name': 'Fashion Hub', 'location': 'Delhi, NCR', 'verified': true, 'specialty': 'Casual Wear'},
    {'name': 'Royal Ethnic Wear', 'location': 'Jaipur, Rajasthan', 'verified': true, 'specialty': 'Wedding Wear'},
    {'name': 'Urban Trends', 'location': 'Bangalore, Karnataka', 'verified': true, 'specialty': 'Modern Ethnic'},
    {'name': 'Indore Silk Store', 'location': 'Indore, MP', 'verified': true, 'specialty': 'Maheshwari Silk'},
  ];
  
  final index = productId.hashCode.abs() % shops.length;
  final shop = shops[index];

  return {
    'shopName': shop['name'],
    'sellerId': 'seller_${productId.substring(0, min(productId.length, 5))}',
    'rating': 4.0 + (productId.length % 10) / 10.0,
    'reviewsCount': 50 + (productId.hashCode.abs() % 500),
    'soldCount': 20 + (productId.hashCode.abs() % 200),
    'location': shop['location'],
    'responseTime': 'Replies in ${1 + (productId.length % 5)} hours',
    'verified': shop['verified'],
    'specialty': shop['specialty'],
    'experience': '${3 + (productId.length % 15)} years in business',
  };
}

int min(int a, int b) => a < b ? a : b;

// Enhanced product description with seller information
String _enhanceDescription(String baseDescription, Map<String, dynamic> sellerInfo) {
  final enhancedDescription = """
$baseDescription

🏪 Seller Information:
• Shop: ${sellerInfo['shopName']}
• Location: ${sellerInfo['location']}
• Response Time: ${sellerInfo['responseTime']}
• Specialty: ${sellerInfo['specialty']}
• Experience: ${sellerInfo['experience']}
• Verified Seller: ${sellerInfo['verified'] ? '✅ Yes' : '❌ No'}

📞 Contact seller directly through chat for any queries about this product!
""";
  return enhancedDescription;
}

// Provider for seller details
final sellerDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  // Simulate API delay for seller details
  await Future.delayed(const Duration(milliseconds: 500));
  return getSellerInfo(productId);
});

// Provider for all seller products
final sellerProductsProvider = FutureProvider.family<List<Product>, String>((ref, sellerId) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 800));
  
  // Return products for the specific seller
  switch (sellerId) {
    case 'seller_001': // Priya Fashion Boutique
      return [
        const Product(
          id: '1',
          name: 'Elegant Silk Saree with Zari Work',
          description: 'Beautiful silk saree with intricate zari work. Perfect for weddings and special occasions.',
          price: 2499.99,
          oldPrice: 3499.99,
          category: 'sarees',
          imagePlaceholder: '👗',
          shopName: 'Priya Fashion Boutique',
          rating: 4.8,
          reviewsCount: 245,
          soldCount: 156,
        ),
        const Product(
          id: '4',
          name: 'Designer Banarasi Saree',
          description: 'Authentic Banarasi silk saree with traditional motifs.',
          price: 3999.99,
          category: 'sarees',
          imagePlaceholder: '🌺',
          shopName: 'Priya Fashion Boutique',
          rating: 4.7,
          reviewsCount: 189,
          soldCount: 98,
        ),
      ];
    case 'seller_002': // Fashion Hub
      return [
        const Product(
          id: '2',
          name: 'Designer Kurti with Embroidery',
          description: 'Stylish designer kurti with beautiful embroidery work.',
          price: 899.99,
          oldPrice: 1299.99,
          category: 'kurtis',
          imagePlaceholder: '👚',
          shopName: 'Fashion Hub',
          rating: 4.5,
          reviewsCount: 128,
          soldCount: 89,
        ),
        const Product(
          id: '5',
          name: 'Casual Cotton Kurti',
          description: 'Comfortable cotton kurti for daily wear.',
          price: 599.99,
          category: 'kurtis',
          imagePlaceholder: '🌸',
          shopName: 'Fashion Hub',
          rating: 4.3,
          reviewsCount: 67,
          soldCount: 145,
        ),
      ];
    case 'seller_003': // Royal Ethnic Wear
      return [
        const Product(
          id: '3',
          name: 'Traditional Lehenga Choli',
          description: 'Exquisite traditional lehenga choli set with heavy embroidery.',
          price: 4999.99,
          oldPrice: 6999.99,
          category: 'lehenga',
          imagePlaceholder: '👘',
          shopName: 'Royal Ethnic Wear',
          rating: 4.9,
          reviewsCount: 89,
          soldCount: 45,
        ),
      ];
    default:
      return [];
  }
});
