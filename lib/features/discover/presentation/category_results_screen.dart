import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../data/mock/mock_data.dart';

class CategoryResultsScreen extends StatelessWidget {
  final String category;
  const CategoryResultsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final products = MockData.products;
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
      body: Column(
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
    );
  }
}
