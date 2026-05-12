import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/seller_providers.dart';
import '../../../shared/models/product.dart';

import 'package:go_router/go_router.dart';

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Products', style: AppTextStyles.h3),
        actions: [
          IconButton(
            onPressed: () => context.push('/seller/products/add'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                        prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.card.withOpacity(0.8),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.muted,
                labelStyle: AppTextStyles.labelMedium,
                tabs: const [
                  Tab(text: 'All (12)'),
                  Tab(text: 'Active (9)'),
                  Tab(text: 'Draft (2)'),
                  Tab(text: 'Out of Stock (1)'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(products),
              _buildProductList(products), // In real app, filter these
              _buildProductList(products),
              _buildProductList(products),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItem(
          product.imagePlaceholder,
          product.name,
          'Stock: ${product.stockCount} · ⭐ ${product.rating}',
          '₹${product.price}',
        );
      },
    );
  }

  Widget _buildProductItem(String icon, String name, String meta, String price, {bool isDraft = false, bool isOutOfStock = false}) {
    return GestureDetector(
      onTap: () => context.push('/home/product/1'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOutOfStock ? const Color(0xFFFFF5F5) : (isDraft ? AppColors.background : AppColors.card),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOutOfStock ? const Color(0xFFFCA5A5) : AppColors.border,
            width: isDraft ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product_img_${name.hashCode}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDraft ? AppColors.border : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: icon.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        icon,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, size: 24, color: Colors.white54),
                      ),
                    )
                  : Text(icon, style: const TextStyle(fontSize: 28, decoration: TextDecoration.none)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge.copyWith(color: isDraft ? AppColors.muted : AppColors.text)),
                  Text(
                    meta,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isOutOfStock ? AppColors.danger : AppColors.muted,
                    ),
                  ),
                  Text(price, style: AppTextStyles.h4.copyWith(color: isDraft ? AppColors.muted : AppColors.text)),
                ],
              ),
            ),
            Column(
              children: [
                if (isDraft)
                  Row(
                    children: [
                      _buildActionBtn('Edit', Icons.edit_outlined, AppColors.secondary, () => context.push('/seller/products/add')),
                      const SizedBox(width: 4),
                      _buildActionBtn('Upload', Icons.cloud_upload_outlined, AppColors.success, () {}, bg: const Color(0xFFDCFCE7), border: const Color(0xFF86EFAC)),
                    ],
                  )
                else if (isOutOfStock)
                  Row(
                    children: [
                      _buildActionBtn('Edit', Icons.edit_outlined, AppColors.secondary, () => context.push('/seller/products/add')),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Restock successful!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'Restock',
                            style: AppTextStyles.labelSmall.copyWith(color: const Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildActionBtn('Edit', Icons.edit_outlined, AppColors.secondary, () => context.push('/seller/products/add')),
                      const SizedBox(width: 4),
                      _buildActionBtn('Delete', Icons.delete_outline, AppColors.primary, () {}),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String action, IconData icon, Color color, VoidCallback onTap, {Color? bg, Color? border}) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$action successful!')),
            );
            onTap();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg ?? Colors.transparent,
              border: Border.all(color: border ?? AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        );
      }
    );
  }
}
