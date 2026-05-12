import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/dynamic_product_providers.dart';
import '../../../shared/providers/mock_product_providers.dart';
import '../../../shared/models/product.dart';

class CustomProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;
  const CustomProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<CustomProductDetailScreen> createState() => _CustomProductDetailScreenState();
}

class _CustomProductDetailScreenState extends ConsumerState<CustomProductDetailScreen> {
  bool isLiked = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final productAsync = ref.watch(dynamicProductDetailProvider(widget.productId!));

    return productAsync.when(
      data: (product) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductSection(product),
                _buildDescriptionSection(product),
                _buildSellerInfoSection(),
                _buildRelatedProductsSection(),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.text),
        onPressed: () => context.pop(),
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.text),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cart functionality coming soon!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProductSection(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Price and description
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${product.price.toInt()}',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 28,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (product.oldPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.oldPrice!.toInt()}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.muted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  product.name,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                    Text(
                      ' ${product.rating}',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' (${product.reviewsCount} reviews)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Message option below price and description
                GestureDetector(
                  onTap: () {
                    context.push('/home/chat/${product.shopName}?product=${product.id}');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.message, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Message Seller',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right side - Image with like option
          Container(
            width: 180,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              children: [
                // Product Image
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      product.imagePlaceholder,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                ),
                // Like option on top right of image
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isLiked = !isLiked;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isLiked ? 'Added to favorites! ❤️' : 'Removed from favorites'),
                          backgroundColor: isLiked ? Colors.green : Colors.grey,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : AppColors.text,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(Product product) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              height: 1.7,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Category', product.category),
              ),
              Expanded(
                child: _buildDetailItem('Sold', '${product.soldCount}+'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Shop', product.shopName),
              ),
              Expanded(
                child: _buildDetailItem('Rating', '${product.rating}⭐'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfoSection() {
    return Consumer(
      builder: (context, ref, child) {
        final sellerDetailsAsync = ref.watch(sellerDetailsProvider(widget.productId!));
        
        return sellerDetailsAsync.when(
          data: (sellerInfo) => Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.store, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Seller Information',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    if (sellerInfo['verified'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Colors.blue, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Shop Name and Rating
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sellerInfo['shopName'],
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.accent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${sellerInfo['rating']}',
                                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                ' (${sellerInfo['reviewsCount']} reviews)',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/home/chat/${sellerInfo['shopName']}?product=${widget.productId}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Message', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Seller Details Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildSellerDetailItem('📍', 'Location', sellerInfo['location']),
                    _buildSellerDetailItem('⏰', 'Response', sellerInfo['responseTime']),
                    _buildSellerDetailItem('🎯', 'Specialty', sellerInfo['specialty']),
                    _buildSellerDetailItem('📊', 'Sold', '${sellerInfo['soldCount']}+ items'),
                  ],
                ),
                const SizedBox(height: 12),
                // Experience
                Row(
                  children: [
                    Icon(Icons.business, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${sellerInfo['experience']} • ${sellerInfo['soldCount']}+ products sold',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.green.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => Container(
            margin: const EdgeInsets.all(16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSellerDetailItem(String icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProductsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Products',
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Related products grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildRelatedProductCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProductCard(int index) {
    final relatedProducts = [
      {'name': 'Designer Kurti', 'price': 899.99, 'emoji': '👚'},
      {'name': 'Silk Saree', 'price': 2499.99, 'emoji': '👗'},
      {'name': 'Lehenga Set', 'price': 4999.99, 'emoji': '👘'},
      {'name': 'Ethnic Wear', 'price': 1999.99, 'emoji': '🌸'},
    ];

    final product = relatedProducts[index];
    
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${product['name']}...')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
                  ),
                ),
                child: Center(
                  child: Text(
                    product['emoji']?.toString() ?? '📦',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name']?.toString() ?? 'Product',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${product['price'] ?? 0}',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
