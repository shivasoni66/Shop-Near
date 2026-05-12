import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/section_header.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/order_providers.dart';
import '../../../shared/providers/user_providers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/user.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _livePulseController;

  @override
  void initState() {
    super.initState();
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Connect socket and listen for orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.connect();
      socketService.on('newOrder', (data) {
        ref.invalidate(sellerOrdersProvider);
      });
    });
  }

  @override
  void dispose() {
    _livePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            userAsync.when(
              data: (user) => _buildHeader(context, user),
              loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => _buildHeader(context, null),
            ),
            _buildStatsGrid(context),
            const SectionHeader(
              title: '📊 Weekly Revenue',
              actionText: '23% vs last week',
            ),
            _buildRevenueChart(),
            const SectionHeader(title: 'Quick Actions'),
            _buildQuickActions(context),
            SectionHeader(
              title: '📦 Recent Orders',
              actionText: 'View All',
              onActionTap: () => context.go('/seller/orders'),
            ),
            _buildRecentOrders(context),
            const SectionHeader(title: '🏆 Achievements'),
            _buildAchievements(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFFFF6B35)],
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: Container(color: Colors.transparent),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 64, 16, 56),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back 👋',
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Seller',
                    style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildHeaderIcon(Icons.notifications_none, () => context.push('/home/notifications')),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(Icons.settings_outlined, () => context.push('/home/settings')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _buildStatCard(context, '₹24K', 'Today', Icons.trending_up, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(context, '18', 'Orders', Icons.shopping_bag_outlined, AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(context, '342', 'Viewers', Icons.visibility_outlined, AppColors.accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => context.go('/seller/analytics'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h3.copyWith(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final List<double> heights = [0.38, 0.62, 0.48, 0.82, 0.68, 0.91, 0.74];
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(heights.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: 100 * heights[index],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            index == 6 ? AppColors.accent : AppColors.primary,
                            (index == 6 ? AppColors.accent : AppColors.primary).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: days.map((day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          _buildActionBtn(
            context,
            Icons.sensors,
            AppColors.liveRed,
            'Go Live Now',
            'Start session',
            () => context.push('/seller/golive'),
            isPulse: true,
          ),
          _buildActionBtn(
            context,
            Icons.add_circle_outline,
            AppColors.secondary,
            'Add Product',
            'List new item',
            () => context.push('/seller/products/add'),
          ),
          _buildActionBtn(
            context,
            Icons.video_camera_back_outlined,
            AppColors.accent,
            'Post Reel',
            'Short video',
            () => context.push('/seller/post-reel'),
          ),
          _buildActionBtn(
            context,
            Icons.chat_bubble_outline,
            AppColors.success,
            'Messages',
            '5 unread',
            () => context.go('/home/chat'),
            subColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, IconData icon, Color color, String label, String sub, VoidCallback onTap, {Color? subColor, bool isPulse = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _livePulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isPulse ? color.withOpacity(_livePulseController.value) : AppColors.border,
                width: isPulse ? 2 : 1.5,
              ),
              boxShadow: isPulse ? [
                BoxShadow(
                  color: color.withOpacity(0.2 * _livePulseController.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(label, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(
                  sub,
                  style: AppTextStyles.labelSmall.copyWith(color: subColor ?? AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentOrders(BuildContext context) {
    final ordersAsync = ref.watch(sellerOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No orders yet'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: orders.take(3).map((order) {
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
                default:
                  statusBg = AppColors.border;
                  statusText = AppColors.text;
              }

              return _buildOrderItem(
                context,
                order.productPlaceholder,
                order.productName,
                '${order.buyerName} · ₹${order.amount.toInt()}',
                order.status,
                statusBg,
                statusText,
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildOrderItem(BuildContext context, String icon, String name, String sub, String status, Color statusBg, Color statusText) {
    return GestureDetector(
      onTap: () => context.go('/seller/orders'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: AppTextStyles.labelSmall.copyWith(color: statusText, fontWeight: FontWeight.w900, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildBadge(context, '🌟', 'Top Seller', true)),
          const SizedBox(width: 10),
          Expanded(child: _buildBadge(context, '🔥', 'Hot Streak', true)),
          const SizedBox(width: 10),
          Expanded(child: _buildBadge(context, '💬', 'Responsive', true)),
          const SizedBox(width: 10),
          Expanded(child: _buildBadge(context, '🎯', '100 Sales', false)),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String emoji, String name, bool earned) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(earned ? 'You have earned the $name badge! 🏆' : 'Complete 100 sales to earn the $name badge! 🎯'),
            backgroundColor: earned ? AppColors.success : AppColors.muted,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: earned ? const Color(0xFFFFFBF0) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: earned ? AppColors.accent : AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
