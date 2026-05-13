import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shop_near/shared/providers/cart_providers.dart';
import 'package:shop_near/shared/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/dynamic_product_providers.dart';
import '../../../shared/providers/mock_product_providers.dart';
import '../../../shared/providers/product_providers.dart';
import '../../../shared/models/product.dart';

class CustomProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;
  const CustomProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<CustomProductDetailScreen> createState() =>
      _CustomProductDetailScreenState();
}

class _CustomProductDetailScreenState
    extends ConsumerState<CustomProductDetailScreen> {
  bool isLiked = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final productAsync =
        ref.watch(dynamicProductDetailProvider(widget.productId!));

    return productAsync.when(
      data: (product) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, product),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductSection(product),
                _buildDescriptionSection(product),
                _buildSellerInfoSection(product),
                _buildRelatedProductsSection(product.category, product.id),
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
          bottomSheet: _buildBottomBar(product),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Product product) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        product.name,
        style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.text),
          onPressed: () => context.push('/home/cart'),
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
                const SizedBox(height: 16),
                // Chat Us option below price and description
                GestureDetector(
                  onTap: () {
                    context.push(
                        '/home/chat/${product.shopName}?product=${product.id}');
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
                        const Icon(Icons.chat_bubble_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Chat Us',
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
                    gradient: LinearGradient(
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
                              borderRadius: BorderRadius.circular(12),
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
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    product.imagePlaceholder,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 50, color: Colors.white54),
                                  ),
                                )
                              : Text(
                                  product.imagePlaceholder,
                                  style: const TextStyle(fontSize: 80),
                                ),
                        ),
                ),
                // Indicator for multiple images
                if (product.images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.images.length,
                        (index) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
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
                          content: Text(isLiked
                              ? 'Added to favorites! ❤️'
                              : 'Removed from favorites'),
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
              const Spacer(),
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

  Widget _buildSellerInfoSection(Product product) {
    return Consumer(
      builder: (context, ref, child) {
        final sellerDetailsAsync = ref.watch(sellerDetailsProvider(product.id));

        return sellerDetailsAsync.when(
          data: (sellerInfo) {
            // Merge actual product data with dynamic seller info
            final shopName = product.shopName.isNotEmpty ? product.shopName : sellerInfo['shopName'];
            final rating = product.rating > 0 ? product.rating : sellerInfo['rating'];
            
            return Container(
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
                      Icon(Icons.store_rounded, color: Colors.green.shade700, size: 22),
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
                      if (sellerInfo['verified'] == true)
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
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 12),
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.shade100,
                        child: Text(shopName[0].toUpperCase(), style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const SizedBox(height: 2),
                            Text(
                              'Verified Seller',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/home/chat/${shopName}?product=${product.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text('Chat Us', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildSellerDetailItem('📍', 'Location', sellerInfo['location'] ?? 'Indore, India'),
                      _buildSellerDetailItem('⏰', 'Response', sellerInfo['responseTime'] ?? 'Fast response'),
                      _buildSellerDetailItem('🎯', 'Specialty', sellerInfo['specialty'] ?? product.category),
                      _buildSellerDetailItem('📊', 'Sold', '${product.soldCount}+ items'),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildRelatedProductsSection(String category, String currentId) {
    return Consumer(
      builder: (context, ref, child) {
        final categoryProductsAsync = ref.watch(categoryProductsProvider(category));

        return categoryProductsAsync.when(
          data: (products) {
            final filteredProducts = products.where((p) => p.id != currentId).toList();
            if (filteredProducts.isEmpty) return const SizedBox.shrink();

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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length > 4 ? 4 : filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildRelatedProductCard(filteredProducts[index]);
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildRelatedProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        context.pushReplacement('/home/product/${product.id}');
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
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    colors: [
                      _getDynamicColor(product.name),
                      _getDynamicColor(product.name).withOpacity(0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    product.imagePlaceholder,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '₹${product.price.toInt()}',
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

  bool isAddedToCart = false;

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Wishlist (Heart)
          GestureDetector(
            onTap: () {
              setState(() => isLiked = !isLiked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isLiked ? 'Saved to your wishlist! ❤️' : 'Removed from wishlist'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: isLiked ? Colors.redAccent : Colors.grey[800],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLiked ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isLiked ? Colors.red.withOpacity(0.3) : Colors.transparent),
              ),
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.red : AppColors.text,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 2. Add to Cart
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
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
                        SnackBar(content: Text('Failed to add to cart: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAddedToCart ? Colors.green.shade50 : Colors.white,
                foregroundColor: isAddedToCart ? Colors.green : AppColors.primary,
                side: BorderSide(color: isAddedToCart ? Colors.green : AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isAddedToCart ? 'ADDED ✓' : 'ADD TO CART',
                  key: ValueKey(isAddedToCart),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 3. Buy Now
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/home/checkout/${product.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'BUY NOW',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddedToCartPopup() {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 500),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: Colors.white,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                      const SizedBox(height: 20),
                      Text('Added to Cart!', style: AppTextStyles.h3),
                      const SizedBox(height: 10),
                      const Text('Your item is ready for checkout.', textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        child: const Text('Continue Shopping'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBuyNow(Product product) async {
    final sellerInfoAsync = ref.read(sellerDetailsProvider(product.id));

    sellerInfoAsync.when(
      data: (sellerInfo) async {
        try {
          final repository = ref.read(orderRepositoryProvider);
          await repository.placeOrder({
            'productId': product.id,
            'sellerId': sellerInfo['sellerId'] ?? 'seller_001',
            'amount': product.price,
            'paymentMethod': 'COD',
          });

          if (mounted) {
            _showSuccessDialog(product);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to place order: $e'),
                  backgroundColor: AppColors.primary),
            );
          }
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  void _showSuccessDialog(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your order for ${product.name} has been sent to the seller.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Shopping',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDynamicColor(String name) {
    final colors = [
      const Color(0xFFFF9A9E), // Pink
      const Color(0xFFA18CD1), // Purple
      const Color(0xFFFBC2EB), // Lavender
      const Color(0xFF84FAB0), // Mint
      const Color(0xFFE0C3FC), // Light Purple
      const Color(0xFFFFECD2), // Peach
      const Color(0xFFCFD9DF), // Silver
      const Color(0xFF8EC5FC), // Sky Blue
    ];
    // Generate a consistent color based on the name hash
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}
