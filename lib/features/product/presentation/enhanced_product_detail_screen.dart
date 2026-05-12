import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/mock_product_providers.dart';
import '../../../shared/models/product.dart';

class EnhancedProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;
  const EnhancedProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<EnhancedProductDetailScreen> createState() => _EnhancedProductDetailScreenState();
}

class _EnhancedProductDetailScreenState extends ConsumerState<EnhancedProductDetailScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String? selectedSize;
  String? selectedColor;
  int quantity = 1;
  bool isFavorite = false;
  int selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final productAsync = ref.watch(mockProductDetailProvider(widget.productId!));

    return productAsync.when(
      data: (product) {
        final enhancedProduct = EnhancedProduct.fromProduct(product);
        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(enhancedProduct),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductImageSection(enhancedProduct),
                            _buildProductInfoSection(enhancedProduct),
                            _buildSizeColorSection(enhancedProduct),
                            _buildProductDetailsSection(enhancedProduct),
                            _buildShippingInfoSection(enhancedProduct),
                            _buildReviewsSection(enhancedProduct),
                            _buildSellerInfoSection(enhancedProduct),
                            const SizedBox(height: 120), // Space for bottom bar
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomActionBar(enhancedProduct),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildSliverAppBar(EnhancedProduct product) {
    return SliverAppBar(
      expandedHeight: 400,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : AppColors.text,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              isFavorite = !isFavorite;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isFavorite ? 'Added to favorites! ❤️' : 'Removed from favorites'),
                backgroundColor: isFavorite ? Colors.green : Colors.grey,
              ),
            );
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.share, color: AppColors.text, size: 18),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality coming soon! 📤')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_img_${product.id}',
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    product.imagePlaceholder,
                    style: const TextStyle(fontSize: 150, decoration: TextDecoration.none),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImageSection(EnhancedProduct product) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedImageIndex = index;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedImageIndex == index ? AppColors.primary : Colors.grey.shade300,
                  width: selectedImageIndex == index ? 2 : 1,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                child: Center(
                  child: Text(
                    product.imagePlaceholder,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfoSection(EnhancedProduct product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBadge('#${product.category}', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              if (product.soldCount > 100)
                _buildBadge('#Bestseller', const Color(0xFFDCFCE7), const Color(0xFF166534)),
              if (product.discountPercentage > 0)
                _buildBadge('${product.discountPercentage.toInt()}% OFF', const Color(0xFFFFE4E6), const Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: AppTextStyles.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('By ', style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted)),
              Text(
                product.shopName,
                style: AppTextStyles.labelSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₹${product.price.toInt()}',
                style: AppTextStyles.h1.copyWith(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 14),
              if (product.oldPrice != null)
                Text(
                  '₹${product.oldPrice!.toInt()}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    color: AppColors.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'In Stock',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < product.rating.floor() ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${product.rating}',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                ' (${product.reviewsCount} reviews)',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted),
              ),
              const Spacer(),
              Text(
                '${product.soldCount} sold',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeColorSection(EnhancedProduct product) {
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
          // Size Selection
          Text('Select Size', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.sizes.map((size) {
              final isSelected = selectedSize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedSize = size;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Color Selection
          Text('Select Color', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.colors.map((color) {
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    color,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Quantity Selector
          Row(
            children: [
              Text('Quantity', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: quantity > 1 ? () {
                        setState(() {
                          quantity--;
                        });
                      } : null,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsSection(EnhancedProduct product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Details', style: AppTextStyles.labelMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildDetailRow('Fabric', product.fabric),
                _buildDetailRow('Origin', product.origin),
                _buildDetailRow('Care', product.careInstructions),
                _buildDetailRow('Delivery', product.deliveryTime),
                _buildDetailRow('Returns', product.returnPolicy),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Description', style: AppTextStyles.labelMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted, fontSize: 14, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoSection(EnhancedProduct product) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Shipping & Delivery', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          _buildShippingItem('✓ Free shipping on orders above ₹999'),
          _buildShippingItem('✓ Express delivery available'),
          _buildShippingItem('✓ Cash on delivery available'),
          _buildShippingItem('✓ Secure packaging'),
        ],
      ),
    );
  }

  Widget _buildShippingItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildReviewsSection(EnhancedProduct product) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Customer Reviews', style: AppTextStyles.labelMedium.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View all reviews coming soon!')),
                  );
                },
                child: Text('View All', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReview('Anjali S.', 5.0, 'Beautiful color and fabric. Looks exactly like the live session demo. Very happy with the purchase! 😍'),
          _buildReview('Kavita D.', 4.0, 'Fast delivery. The zari work is stunning. Will buy more from ${product.shopName}.'),
          _buildReview('Priya M.', 5.0, 'Excellent quality and perfect fit. The seller was very helpful with sizing questions.'),
        ],
      ),
    );
  }

  Widget _buildReview(String name, double rating, String review) {
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
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.floor() ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(review, style: AppTextStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.muted, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildSellerInfoSection(EnhancedProduct product) {
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
          Text('Seller Information', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFFECD2), Color(0xFFFCB69F)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.shopName,
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.accent, size: 14),
                        const SizedBox(width: 4),
                        Text('4.8', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                        Text(' (234 reviews)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View seller profile coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Visit Store', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(EnhancedProduct product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Message Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (selectedSize == null || selectedColor == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select size and color first!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                context.push('/home/chat/${product.shopName}?product=${product.id}');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.message, color: AppColors.primary, size: 20),
                    const SizedBox(height: 4),
                    Text('Message', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Add to Cart Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (selectedSize == null || selectedColor == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select size and color first!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $quantity item(s) to cart! 🛒'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_shopping_cart, color: Colors.orange.shade700, size: 20),
                    const SizedBox(height: 4),
                    Text('Add to Cart', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Buy Now Button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                if (selectedSize == null || selectedColor == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select size and color first!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                context.push('/home/cart');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.flash_on, color: Colors.white, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      'Buy Now - ₹${(product.price * quantity).toInt()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
