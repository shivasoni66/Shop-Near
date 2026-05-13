import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/dynamic_product_providers.dart';
import '../../../shared/models/product.dart';

class SellerProductDetailScreen extends ConsumerWidget {
  final String? productId;
  const SellerProductDetailScreen({super.key, this.productId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final productAsync = ref.watch(dynamicProductDetailProvider(productId!));

    return productAsync.when(
      data: (product) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Product Insights', style: AppTextStyles.h3),
          actions: [
            IconButton(
              onPressed: () => context.push('/seller/products/add', extra: product),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel Section
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getDynamicColor(product.name), _getDynamicColor(product.name).withOpacity(0.6)],
                  ),
                ),
                child: product.images.isNotEmpty
                    ? PageView.builder(
                        itemCount: product.images.length,
                        itemBuilder: (context, index) => Image.network(product.images[index], fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(product.imagePlaceholder, 
                            style: const TextStyle(fontSize: 100, decoration: TextDecoration.none)),
                      ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(product.category, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                        ),
                        Text('Stock: ${product.stock}', style: AppTextStyles.labelMedium.copyWith(color: product.stock > 0 ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(product.name, style: AppTextStyles.h2.copyWith(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text('₹${product.price}', style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 28)),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: AppColors.border),
                    ),
                    
                    // Seller Stats Grid
                    Row(
                      children: [
                        _buildStatCard('Units Sold', product.soldCount.toString(), Icons.shopping_bag_outlined),
                        const SizedBox(width: 12),
                        _buildStatCard('Views', '1.2k', Icons.visibility_outlined),
                        const SizedBox(width: 12),
                        _buildStatCard('Rating', '⭐ ${product.rating}', Icons.star_outline),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    Text('Description', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 10),
                    Text(product.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted, height: 1.6)),
                    
                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/seller/products/add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Update Inventory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
