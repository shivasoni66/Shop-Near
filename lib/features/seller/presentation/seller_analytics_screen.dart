import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/providers/seller_providers.dart';

class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(sellerAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics & Insights', style: AppTextStyles.h3),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(sellerAnalyticsProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildContent(context, ref, analytics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> analytics) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPeriodSelector(ref),
          _buildSummaryGrid(analytics),
          const SectionHeader(title: '📈 Revenue Trend'),
          _buildSalesChart(analytics['dailyRevenue'] ?? []),
          const SectionHeader(title: '🏆 Top Selling Products'),
          _buildTopProducts(analytics['topProducts'] ?? []),
          const SectionHeader(title: '📡 Live Session Stats'),
          _buildLiveStats(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(WidgetRef ref) {
    final currentPeriod = ref.watch(selectedAnalyticsPeriodProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: ['Week', 'Month', 'Year'].map((p) => Expanded(
          child: GestureDetector(
            onTap: () => ref.read(selectedAnalyticsPeriodProvider.notifier).state = p,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: p == currentPeriod ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p == currentPeriod ? AppColors.primary : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                p,
                style: AppTextStyles.labelMedium.copyWith(color: p == currentPeriod ? Colors.white : AppColors.text),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> analytics) {
    final totalSales = '₹${analytics['totalRevenue'] ?? 0}';
    final ordersCount = analytics['totalOrders']?.toString() ?? '0';
    final conversionRate = analytics['conversionRate']?.toString() ?? '0%';
    final avgOrderValue = '₹${analytics['avgOrderValue'] ?? 0}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total Sales', totalSales, '+0%', true)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Orders', ordersCount, '+0%', true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Conversion', conversionRate, '0%', true)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Avg. Order', avgOrderValue, '+0%', true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String trend, bool positive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: AppTextStyles.h3),
              Text(
                trend,
                style: AppTextStyles.labelSmall.copyWith(color: positive ? AppColors.success : AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<dynamic> dailyData) {
    if (dailyData.isEmpty) {
      return const Center(child: Text('No sales data yet'));
    }

    final maxVal = dailyData.map((e) => (e['amount'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyData.map((data) {
                final amount = (data['amount'] as num).toDouble();
                final h = maxVal > 0 ? (amount / maxVal) : 0.05;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('₹${amount.toInt()}', style: const TextStyle(fontSize: 8, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 120 * h.clamp(0.05, 1.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.3)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: dailyData.map((data) => Expanded(
              child: Text(
                data['day'].toString(),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<dynamic> topProducts) {
    if (topProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: const Center(child: Text('No sales yet 🏆')),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: topProducts.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return Column(
            children: [
              _buildTopProductItem(
                (index + 1).toString(), 
                product['image'], 
                product['name'], 
                '${product['sold']} sold', 
                '₹${product['revenue']}', 
                index == 0 ? const Color(0xFFFEF3C7) : index == 1 ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7), 
                index == 0 ? const Color(0xFF92400E) : index == 1 ? const Color(0xFF1E40AF) : const Color(0xFF166534)
              ),
              if (index < topProducts.length - 1) const Divider(color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProductItem(String rank, String imageUrl, String name, String sold, String rev, Color rankBg, Color rankText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: rankBg, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Text(rank, style: AppTextStyles.labelSmall.copyWith(color: rankText, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background, 
              borderRadius: BorderRadius.circular(10),
              image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
            ),
            alignment: Alignment.center,
            child: imageUrl.isEmpty ? const Text('📦') : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelMedium),
                Text(sold, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Text(rev, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildLiveStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildStatRow('Sessions this week', '7 sessions'),
          _buildStatRow('Avg viewers', '247'),
          _buildStatRow('Avg session duration', '42 min'),
          _buildStatRow('Orders from live', '68 (46%)', valueColor: AppColors.success),
          _buildStatRow('Conversion rate', '7.3%', valueColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: valueColor ?? AppColors.text)),
        ],
      ),
    );
  }
}
