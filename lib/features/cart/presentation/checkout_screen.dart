import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/dynamic_product_providers.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/repository_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String productId;
  const CheckoutScreen({super.key, required this.productId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPaymentMethod = 'UPI';
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(dynamicProductDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: productAsync.when(
        data: (product) => _buildBody(product),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: productAsync.when(
        data: (product) => _buildBottomBar(product),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBody(Product product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Delivery Address
          _buildSectionHeader('Delivery Address'),
          _buildAddressCard(),
          const SizedBox(height: 24),

          // 2. Order Summary
          _buildSectionHeader('Order Summary'),
          _buildProductCard(product),
          const SizedBox(height: 24),

          // 3. Payment Methods
          _buildSectionHeader('Payment Method'),
          _buildPaymentMethods(),
          const SizedBox(height: 24),

          // 4. Price Breakdown
          _buildPriceBreakdown(product),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '123, Vijay Nagar, Indore, Madhya Pradesh - 452010',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Center(
              child: product.imagePlaceholder.startsWith('http')
                  ? Image.network(product.imagePlaceholder, fit: BoxFit.cover)
                  : Text(product.imagePlaceholder, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(product.shopName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                const SizedBox(height: 8),
                Text(
                  '₹${product.price.toInt()}',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      {'id': 'UPI', 'name': 'UPI App', 'icon': Icons.account_balance_wallet_rounded},
      {'id': 'CARD', 'name': 'Credit/Debit Card', 'icon': Icons.credit_card_rounded},
      {'id': 'COD', 'name': 'Cash on Delivery', 'icon': Icons.money_rounded},
    ];

    return Column(
      children: methods.map((m) => GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = m['id'] as String),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedPaymentMethod == m['id'] ? AppColors.primary : Colors.grey.shade200,
              width: _selectedPaymentMethod == m['id'] ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(m['icon'] as IconData, color: _selectedPaymentMethod == m['id'] ? AppColors.primary : AppColors.muted),
              const SizedBox(width: 16),
              Text(m['name'] as String, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_selectedPaymentMethod == m['id'])
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildPriceBreakdown(Product product) {
    const delivery = 40.0;
    final total = product.price + delivery;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '₹${product.price.toInt()}'),
          const SizedBox(height: 8),
          _buildPriceRow('Delivery Fee', '₹${delivery.toInt()}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildPriceRow('Total Amount', '₹${total.toInt()}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? AppColors.text : AppColors.muted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? AppColors.primary : AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Product product) {
    const delivery = 40.0;
    final total = product.price + delivery;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total to Pay', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                Text('₹${total.toInt()}', style: AppTextStyles.h2.copyWith(color: AppColors.primary, fontSize: 24)),
              ],
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : () => _placeOrder(product, total),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isPlacingOrder 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Place Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(Product product, double total) async {
    setState(() => _isPlacingOrder = true);
    
    try {
      final repository = ref.read(orderRepositoryProvider);
      
      // Fetch seller info for the order
      final sellerInfo = await ref.read(sellerDetailsProvider(product.id).future);
      
      await repository.placeOrder({
        'productId': product.id,
        'sellerId': sellerInfo['sellerId'] ?? 'seller_001',
        'amount': total,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'Pending',
      });

      if (mounted) {
        _showSuccessDialog(product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showSuccessDialog(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text('Order Successful!', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Text(
              'Your order for ${product.name} has been placed successfully.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue Shopping', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
