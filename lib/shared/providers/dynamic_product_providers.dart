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
  
  return Product(
    id: baseProduct.id,
    name: baseProduct.name,
    shopName: sellerInfo['shopName'],
    price: baseProduct.price,
    oldPrice: baseProduct.oldPrice,
    rating: sellerInfo['rating'],
    reviewsCount: sellerInfo['reviewsCount'],
    soldCount: sellerInfo['soldCount'],
    stockCount: baseProduct.stockCount,
    imagePlaceholder: baseProduct.imagePlaceholder,
    tags: baseProduct.tags,
    description: _enhanceDescription(baseProduct.description, sellerInfo),
    category: baseProduct.category,
  );
}

// Dynamic seller information based on product ID
Map<String, dynamic> getSellerInfo(String productId) {
  switch (productId) {
    case '1':
      return {
        'shopName': 'Priya Fashion Boutique',
        'sellerId': 'seller_001',
        'rating': 4.8,
        'reviewsCount': 245,
        'soldCount': 156,
        'location': 'Mumbai, Maharashtra',
        'responseTime': 'Usually replies in 2 hours',
        'verified': true,
        'specialty': 'Traditional & Designer Sarees',
        'experience': '8 years in business',
      };
    case '2':
      return {
        'shopName': 'Fashion Hub',
        'sellerId': 'seller_002',
        'rating': 4.5,
        'reviewsCount': 128,
        'soldCount': 89,
        'location': 'Delhi, NCR',
        'responseTime': 'Usually replies in 1 hour',
        'verified': true,
        'specialty': 'Ethnic & Casual Wear',
        'experience': '5 years in business',
      };
    case '3':
      return {
        'shopName': 'Royal Ethnic Wear',
        'sellerId': 'seller_003',
        'rating': 4.9,
        'reviewsCount': 89,
        'soldCount': 45,
        'location': 'Jaipur, Rajasthan',
        'responseTime': 'Usually replies in 3 hours',
        'verified': true,
        'specialty': 'Wedding & Festival Wear',
        'experience': '12 years in business',
      };
    default:
      return {
        'shopName': 'Ethnic Fashion Store',
        'sellerId': 'seller_004',
        'rating': 4.6,
        'reviewsCount': 156,
        'soldCount': 234,
        'location': 'Bangalore, Karnataka',
        'responseTime': 'Usually replies in 4 hours',
        'verified': true,
        'specialty': 'All Types of Ethnic Wear',
        'experience': '6 years in business',
      };
  }
}

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
