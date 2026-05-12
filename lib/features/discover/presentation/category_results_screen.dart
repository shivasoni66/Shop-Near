import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/providers/product_providers.dart';

class CategoryResultsScreen extends ConsumerWidget {
  final String category;
  const CategoryResultsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If it's one of the main categories, use category provider, otherwise search provider
    final isMainCategory = [
      'Fashion', 'Food', 'Electronics', 'Handicraft', 'Grocery', 'Jewellery',
      'Fashion & Clothing', 'Organic & Natural', 'Food & Snacks'
    ].contains(category);

    final productsAsync = isMainCategory 
        ? ref.watch(categoryProductsProvider(category))
        : ref.watch(searchProductsProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text(category, style: AppTextStyles.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: productsAsync.when(
        data: (products) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Showing items for ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted)),
                  Text('"$category"', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (products.isEmpty)
              const Expanded(child: Center(child: Text('No products found'))),
            if (products.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push('/home/product/${product.id}'),
                    );
                  },
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
