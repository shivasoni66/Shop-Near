import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/cart_providers.dart';
import '../../../shared/models/cart_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: cartAsync.when(
          data: (cartItems) => Text(
            'My Cart (${cartItems.length})',
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          loading: () => const Text('My Cart', style: TextStyle(color: AppColors.text)),
          error: (_, __) => const Text('My Cart', style: TextStyle(color: AppColors.text)),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            child: const Text('Clear All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: cartAsync.when(
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return _buildEmptyCart(context);
          }

          double subtotal = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
          double delivery = subtotal > 500 ? 0 : 40;
          double total = subtotal + delivery;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cartItems.map((item) => _buildCartItem(context, ref, item)),
              const SizedBox(height: 24),
              _buildPriceSummary(subtotal, delivery, total),
              const SizedBox(height: 32),
              _buildCheckoutButton(context, total),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_basket_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text('Your cart is empty', style: AppTextStyles.h3.copyWith(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Start Shopping', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withOpacity(0.05),
            ),
            child: Center(
              child: (item.imagePlaceholder ?? '📦').startsWith('http')
                  ? Image.network(item.imagePlaceholder!, fit: BoxFit.cover)
                  : Text(item.imagePlaceholder ?? '📦', style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(item.shopName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Text('₹${item.price.toInt()}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          // Quantity controls
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
              ),
              Row(
                children: [
                  _qtyBtn(Icons.remove, () => ref.read(cartProvider.notifier).updateQty(item.id, item.quantity - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _qtyBtn(Icons.add, () => ref.read(cartProvider.notifier).updateQty(item.id, item.quantity + 1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.text),
      ),
    );
  }

  Widget _buildPriceSummary(double subtotal, double delivery, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', '₹${subtotal.toInt()}'),
          const SizedBox(height: 12),
          _priceRow('Delivery Fee', delivery == 0 ? 'FREE' : '₹${delivery.toInt()}', isFree: delivery == 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _priceRow('Total Payable', '₹${total.toInt()}', isTotal: true),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? AppColors.text : AppColors.muted, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500, fontSize: isTotal ? 16 : 14)),
        Text(value, style: TextStyle(color: isFree ? Colors.green : (isTotal ? AppColors.primary : AppColors.text), fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, fontSize: isTotal ? 20 : 14)),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, double total) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Processing multiple items checkout...'),
              backgroundColor: AppColors.primary),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text('Checkout · ₹${total.toInt()} →',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
    );
  }
}
