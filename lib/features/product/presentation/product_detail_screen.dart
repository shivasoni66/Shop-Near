import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_near/shared/providers/user_providers.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/dynamic_product_providers.dart';
import '../../../shared/providers/cart_providers.dart';
import '../../../shared/models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with SingleTickerProviderStateMixin {
  bool isAddedToCart = false;

  @override
  void initState() {
    super.initState();
  }

  Color _getDynamicColor(String name) {
    final colors = [
      const Color(0xFFFF9A9E),
      const Color(0xFFA18CD1),
      const Color(0xFFFBC2EB),
      const Color(0xFF84FAB0),
      const Color(0xFFE0C3FC),
      const Color(0xFFFFECD2),
    ];
    return colors[name.length % colors.length];
  }

  void _showAddedToCartPopup() {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.shopping_cart_checkout_rounded, color: Colors.green.shade600, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('Added to Cart!', style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('Item is ready for checkout', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _shareProduct(Product product) {
    Share.share(
      'Check out ${product.name} at ${product.shopName} on ShopNear! 🛍️\n'
      'Price: ₹${product.price.toInt()}\n'
      'Get it now: https://shop-near.com/product/${product.id}',
      subject: 'Look at this product!',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final productAsync = ref.watch(dynamicProductDetailProvider(widget.productId!));

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
                onPressed: () => _shareProduct(product),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getDynamicColor(product.name),
                              _getDynamicColor(product.name).withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: product.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: product.images.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    child: Image.network(
                                      product.images[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 50, color: Colors.white54),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: product.imagePlaceholder.startsWith('http')
                                    ? Image.network(
                                        product.imagePlaceholder,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 50, color: Colors.white54),
                                      )
                                    : Text(product.imagePlaceholder, 
                                        style: const TextStyle(fontSize: 120, decoration: TextDecoration.none)),
                              ),
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
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: AppColors.primary, size: 14),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Wishlist Heart Button
              Positioned(
                top: 340,
                right: 20,
                child: Consumer(
                  builder: (context, ref, child) {
                    ref.watch(userWishlistProvider);
                    final isWishlisted = ref.read(userWishlistProvider.notifier).isWishlisted(product.id);
                    
                    return GestureDetector(
                      onTap: () => ref.read(userWishlistProvider.notifier).toggle(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.red : AppColors.muted,
                          size: 24,
                        ),
                      ),
                    );
                  },
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
                          onTap: () async {
                            if (!isAddedToCart) {
                              try {
                                await ref.read(cartProvider.notifier).addItem(product.id, 1);
                                setState(() => isAddedToCart = true);
                                if (mounted) {
                                  _showAddedToCartPopup();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              isAddedToCart ? 'Added' : 'Add to Cart',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isAddedToCart ? Colors.green : Colors.white70, 
                                fontSize: 14, 
                                fontWeight: FontWeight.w700
                              ),
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
                            child: const Icon(
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
                          onTap: () => context.push('/home/checkout/${product.id}'),
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
      error: (err, stack) => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: textCol, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}
