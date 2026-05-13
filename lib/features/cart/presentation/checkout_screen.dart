import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../shared/providers/order_providers.dart';
import '../../../shared/providers/user_providers.dart';
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
  String _address = 'Fetching location...';
  bool _isLoadingLocation = true;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _address = 'Location services are disabled.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _address = 'Location permissions are denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _address = 'Location permissions are permanently denied.';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = '${place.name}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} - ${place.postalCode}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() {
        _address = 'Failed to get location. Please enter manually.';
        _isLoadingLocation = false;
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _finalizeOrder();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message ?? "Cancelled"}'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _finalizeOrder();
  }

  Future<void> _finalizeOrder() async {
    final productAsync = ref.read(dynamicProductDetailProvider(widget.productId));
    productAsync.whenData((product) async {
      const delivery = 40.0;
      final total = product.price + delivery;
      
      try {
        final repository = ref.read(orderRepositoryProvider);
        
        final order = await repository.placeOrder({
          'productId': product.id,
          'sellerId': product.sellerId ?? 'seller_001',
          'amount': total,
          'paymentMethod': _selectedPaymentMethod,
          'address': _address,
          'status': 'Pending',
        });

        // Emit socket event for real-time update if needed (backend usually handles this)
        // ref.read(socketServiceProvider).emit('newOrder', order.toMap());

        if (mounted) {
          _showSuccessPopup(product);
          // Invalidate to refresh all order lists immediately
          ref.invalidate(userOrdersProvider);
          ref.invalidate(sellerOrdersProvider);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  void _showSuccessPopup(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 600),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
                    const SizedBox(height: 20),
                    Text('Order Successful!', style: AppTextStyles.h3.copyWith(color: Colors.black)),
                    const SizedBox(height: 8),
                    Text(
                      'Your order for ${product.name} is placed.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
        context.go('/home/profile'); // Go to orders page
      }
    });
  }

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
          _buildSectionHeader('Delivery Address'),
          _buildAddressCard(),
          const SizedBox(height: 24),

          _buildSectionHeader('Order Summary'),
          _buildProductCard(product),
          const SizedBox(height: 24),

          _buildSectionHeader('Payment Method'),
          _buildPaymentMethods(),
          const SizedBox(height: 24),

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
        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black),
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
                Text('Current Location', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.black)),
                const SizedBox(height: 4),
                _isLoadingLocation 
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _address,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[800]),
                    ),
              ],
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.images.isNotEmpty
                ? Image.network(product.images[0], fit: BoxFit.cover)
                : Center(child: Text(product.imagePlaceholder, style: const TextStyle(fontSize: 32))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.black)),
                const SizedBox(height: 4),
                Text(product.shopName, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[700])),
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
      {'id': 'RAZORPAY', 'name': 'Razorpay / UPI / Card', 'icon': Icons.payment_rounded},
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
              Text(m['name'] as String, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.black)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            color: isTotal ? AppColors.primary : Colors.black,
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
              onPressed: _isPlacingOrder ? null : () => _startOrder(product, total),
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

  void _startOrder(Product product, double total) {
    if (_address == 'Fetching location...' || _isLoadingLocation) {
      _getCurrentLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, fetching location...'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    if (_selectedPaymentMethod == 'RAZORPAY') {
      var options = {
        'key': 'rzp_test_rYnIAnkUoFpLTM', // Real test key (or user's)
        'amount': (total * 100).toInt(),
        'name': 'ShopNear',
        'description': 'Order for ${product.name}',
        'prefill': {
          'contact': '9876543210',
          'email': 'buyer@shopnear.com'
        },
        'timeout': 300, // 5 minutes
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay open error: $e');
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open Razorpay: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // For COD, finalize directly
      _finalizeOrder();
    }
  }
}
