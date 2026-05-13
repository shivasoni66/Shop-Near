import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/order_providers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/models/order.dart';
import '../../../shared/providers/user_providers.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Connect socket and listen for orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider).value;
      if (user != null) {
        final socketService = ref.read(socketServiceProvider);
        socketService.connect();
        socketService.on('new_order_${user.id}', (data) {
          // Refresh orders when a new order arrives for this specific seller
          ref.invalidate(sellerOrdersProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New order received! 📦'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Orders', style: AppTextStyles.h3.copyWith(color: Colors.black)),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(sellerOrdersProvider), 
            icon: const Icon(Icons.refresh, color: Colors.black)
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w900),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Packing'),
            Tab(text: 'Out for Delivery'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: ordersAsync.when(
        data: (orders) => TabBarView(
          controller: _tabController,
          children: [
            _buildOrderList(orders),
            _buildOrderList(orders.where((o) => o.status == 'Pending').toList()),
            _buildOrderList(orders.where((o) => o.status == 'Packing').toList()),
            _buildOrderList(orders.where((o) => o.status == 'Out for Delivery').toList()),
            _buildOrderList(orders.where((o) => o.status == 'Delivered').toList()),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No orders yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        Color statusBg;
        Color statusText;
        
        switch (order.status) {
          case 'Pending':
            statusBg = const Color(0xFFFEF3C7);
            statusText = const Color(0xFF92400E);
            break;
          case 'Packing':
            statusBg = const Color(0xFFDBEAFE);
            statusText = const Color(0xFF1E40AF);
            break;
          case 'Out for Delivery':
            statusBg = const Color(0xFFE0E7FF);
            statusText = const Color(0xFF3730A3);
            break;
          case 'Delivered':
            statusBg = const Color(0xFFDCFCE7);
            statusText = const Color(0xFF166534);
            break;
          default:
            statusBg = AppColors.border;
            statusText = AppColors.text;
        }

        return _buildOrderCard(
          order.id,
          order.productPlaceholder,
          order.productName,
          '#${order.id.substring(order.id.length - math.min(4, order.id.length))}',
          '${order.buyerName} · ₹${order.amount.toInt()} · ${order.paymentMethod}',
          order.status,
          statusBg,
          statusText,
          status: order.status,
          orderAddress: order.address,
        );
      },
    );
  }

  Widget _buildOrderCard(
    String id, 
    String icon, 
    String name, 
    String orderId, 
    String buyerDetails, 
    String statusLabel, 
    Color statusBg, 
    Color statusText, 
    {required String status, String? orderAddress}
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelLarge.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(orderId, style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(color: statusText, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Text(buyerDetails, style: AppTextStyles.bodySmall.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
          if (orderAddress != null && orderAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      orderAddress,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: Colors.grey[800]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (status != 'Delivered' && status != 'Cancelled')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final repository = ref.read(orderRepositoryProvider);
                    String nextStatus = '';
                    if (status == 'Pending') nextStatus = 'Packing';
                    else if (status == 'Packing') nextStatus = 'Out for Delivery';
                    else if (status == 'Out for Delivery') nextStatus = 'Delivered';

                    await repository.updateOrderStatus(id, nextStatus);
                    ref.invalidate(sellerOrdersProvider);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order $orderId moved to $nextStatus! 🚚'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  status == 'Pending' ? 'Accept Order' : 
                  status == 'Packing' ? 'Mark Out for Delivery' : 'Mark Delivered',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
