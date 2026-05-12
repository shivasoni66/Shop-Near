import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/product_providers.dart';
import '../../../shared/providers/mock_product_providers.dart';
import '../../../shared/models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final productAsync = ref.watch(productDetailProvider(widget.productId!));

    return productAsync.when(
      data: (product) {
        final String heroTag = 'product_img_${product.id}';
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chevron_left, color: AppColors.text, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.share, color: AppColors.text, size: 18),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: Container(
                        height: 380,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(product.imagePlaceholder, style: const TextStyle(fontSize: 120, decoration: TextDecoration.none)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildBadge('#${product.category}', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
                              const SizedBox(width: 8),
                              if (product.soldCount > 100)
                                _buildBadge('#Bestseller', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(product.name, style: AppTextStyles.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('By ', style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted)),
                              Text(product.shopName, style: AppTextStyles.labelSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('₹${product.price.toInt()}', style: AppTextStyles.h1.copyWith(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 14),
                              if (product.oldPrice != null)
                                Text('₹${product.oldPrice!.toInt()}', style: AppTextStyles.bodyMedium.copyWith(fontSize: 16, color: AppColors.muted, decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                              Text(' ${product.rating} ', style: AppTextStyles.labelSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
                              Text('(${product.reviewsCount} reviews)', style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          Text('Product Details', style: AppTextStyles.labelMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted, fontSize: 14, height: 1.7),
                          ),
                          const SizedBox(height: 24),
                          
                          const SizedBox(height: 24),
                          Text('Top Reviews', style: AppTextStyles.labelMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          _buildReview('Anjali S.', 'Beautiful color and fabric. Looks exactly like the live session demo. Very happy with the purchase! 😍'),
                          _buildReview('Kavita D.', 'Fast delivery. The zari work is stunning. Will buy more from Priya Fashion.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Floating Bottom Action Bar
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to Cart! 🛒')),
                            );
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Add to Cart',
                              style: AppTextStyles.labelMedium.copyWith(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/home/chat/${product.shopName}?product=${product.id}'),
                          child: Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.message_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => context.push('/home/cart'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Buy Now',
                              style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: textCol, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
      child: const Icon(Icons.check, color: Colors.white, size: 8),
    );
  }

  Widget _buildReview(String name, String review) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: AppTextStyles.labelSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
              const Spacer(),
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 14),
            ],
          ),
          const SizedBox(height: 4),
          Text(review, style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted, height: 1.6)),
        ],
      ),
    );
  }
}
