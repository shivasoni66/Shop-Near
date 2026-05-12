import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// Mock data provider to avoid API issues during development
final mockProductDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 800));
  
  // Return mock product based on ID
  switch (id) {
    case '1':
      return const Product(
        id: '1',
        name: 'Elegant Silk Saree with Zari Work',
        description: 'Beautiful silk saree with intricate zari work. Perfect for weddings and special occasions. Made from premium quality silk with traditional hand-woven patterns. The saree features a rich pallu with detailed motifs and comes with a matching blouse piece.',
        price: 2499.99,
        oldPrice: 3499.99,
        category: 'sarees',
        imagePlaceholder: '👗',
        shopName: 'Priya Fashion Boutique',
        rating: 4.8,
        reviewsCount: 245,
        soldCount: 156,
      );
    case '2':
      return const Product(
        id: '2',
        name: 'Designer Kurti with Embroidery',
        description: 'Stylish designer kurti with beautiful embroidery work. Comfortable and elegant, perfect for casual and semi-formal occasions. Made from high-quality cotton fabric with detailed thread work on the neckline and sleeves.',
        price: 899.99,
        oldPrice: 1299.99,
        category: 'kurtis',
        imagePlaceholder: '👚',
        shopName: 'Fashion Hub',
        rating: 4.5,
        reviewsCount: 128,
        soldCount: 89,
      );
    case '3':
      return const Product(
        id: '3',
        name: 'Traditional Lehenga Choli',
        description: 'Exquisite traditional lehenga choli set with heavy embroidery. Ideal for weddings and festivals. The set includes lehenga, choli, and dupatta with matching accessories.',
        price: 4999.99,
        oldPrice: 6999.99,
        category: 'lehenga',
        imagePlaceholder: '👘',
        shopName: 'Royal Ethnic Wear',
        rating: 4.9,
        reviewsCount: 89,
        soldCount: 45,
      );
    default:
      // Return a default product for any other ID
      return Product(
        id: id,
        name: 'Premium Ethnic Wear',
        description: 'High-quality ethnic wear perfect for any occasion. Made with premium fabrics and traditional craftsmanship.',
        price: 1999.99,
        oldPrice: 2499.99,
        category: 'ethnic',
        imagePlaceholder: '🌸',
        shopName: 'Ethnic Fashion Store',
        rating: 4.6,
        reviewsCount: 156,
        soldCount: 234,
      );
  }
});

// Enhanced product model with additional shopping platform features
class EnhancedProduct {
  final Product product;
  final List<String> sizes;
  final List<String> colors;
  final String fabric;
  final String careInstructions;
  final String origin;
  final String deliveryTime;
  final String returnPolicy;
  final bool isExpressDelivery;
  final double discountPercentage;

  EnhancedProduct({
    required this.product,
    this.sizes = const ['S', 'M', 'L', 'XL'],
    this.colors = const ['Red', 'Blue', 'Green'],
    this.fabric = 'Premium Quality',
    this.careInstructions = 'Gentle wash recommended',
    this.origin = 'India',
    this.deliveryTime = '3-5 business days',
    this.returnPolicy = '7 days return available',
    this.isExpressDelivery = false,
    this.discountPercentage = 0.0,
  });

  factory EnhancedProduct.fromProduct(Product product) {
    return EnhancedProduct(
      product: product,
      discountPercentage: product.oldPrice != null 
          ? ((product.oldPrice! - product.price) / product.oldPrice! * 100)
          : 0.0,
    );
  }

  // Convenience getters to access product properties
  String get id => product.id;
  String get name => product.name;
  String get description => product.description;
  double get price => product.price;
  double? get oldPrice => product.oldPrice;
  String get category => product.category;
  String get imagePlaceholder => product.imagePlaceholder;
  String get shopName => product.shopName;
  double get rating => product.rating;
  int get reviewsCount => product.reviewsCount;
  int get soldCount => product.soldCount;
}
