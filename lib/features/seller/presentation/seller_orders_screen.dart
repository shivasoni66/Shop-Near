import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/order_providers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/models/order.dart';

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
      final socketService = ref.read(socketServiceProvider);
      socketService.connect();
      socketService.on('newOrder', (data) {
        // Refresh orders when a new order arrives
        ref.invalidate(sellerOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New order received! 📦'),
            backgroundColor: AppColors.success,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // In a real app, you might want to stop listening to specific events
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders', style: AppTextStyles.h3),
        actions: [
          IconButton(onPressed: () => ref.invalidate(sellerOrdersProvider), icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          labelStyle: AppTextStyles.labelMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Processing'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
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
            _buildOrderList(orders.where((o) => o.status == 'Delivered').toList()),
            _buildOrderList(orders.where((o) => o.status == 'Cancelled').toList()),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
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
          case 'Delivered':
            statusBg = const Color(0xFFDCFCE7);
            statusText = const Color(0xFF166534);
            break;
          case 'Cancelled':
            statusBg = const Color(0xFFFEE2E2);
            statusText = const Color(0xFFB91C1C);
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
    {required String status}
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order details for $orderId coming soon!')),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '$name ',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.text),
                      children: [
                        TextSpan(text: orderId, style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted, fontSize: 10)),
                      ],
                    ),
                  ),
                  Text(buyerDetails, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(color: statusText, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
                if (status == 'Pending' || status == 'Packing')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          final repository = ref.read(orderRepositoryProvider);
                          final nextStatus = status == 'Pending' ? 'Packing' : 'Delivered';
                          await repository.updateOrderStatus(id, nextStatus);
                          ref.invalidate(sellerOrdersProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order $orderId ${status == 'Pending' ? 'Accepted' : 'Delivered'}! 📦'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: status == 'Pending' ? AppColors.secondary.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                          border: Border.all(
                            color: status == 'Pending' ? AppColors.secondary : AppColors.success, 
                            width: 1.5
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status == 'Pending' ? 'Accept' : 'Mark Delivered',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: status == 'Pending' ? AppColors.secondary : AppColors.success, 
                            fontWeight: FontWeight.w800, 
                            fontSize: 10
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
