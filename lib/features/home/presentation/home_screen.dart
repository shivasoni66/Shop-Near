import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/product_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/chip_filter_row.dart';
import 'widgets/story_row_widget.dart';
import 'widgets/live_cards_row_widget.dart';
import 'widgets/product_grid_widget.dart';
import 'widgets/community_post_card.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';
import '../../../shared/providers/live_providers.dart';
import '../../../shared/providers/repository_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'Fashion', 'Food', 'Electronics', 'Handicraft', 'Grocery', 'Jewellery'
  ];

  @override
  void initState() {
    super.initState();
    // Connect socket and listen for live updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.connect();
      socketService.on('live_update', (data) {
        // When a seller starts or stops a live, refresh our list
        ref.invalidate(liveSessionsProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final isLoading = productsAsync.isLoading;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productsProvider.future),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context),
              const SectionHeader(title: 'Stories & Reels'),
              isLoading ? _buildStoryShimmer() : const StoryRowWidget(),
              SectionHeader(
                title: '🔴 Live Now',
                actionText: 'See all',
                onActionTap: () => context.push('/home/live'),
              ),
              isLoading ? _buildLiveShimmer() : const LiveCardsRowWidget(),
              ChipFilterRow(
                items: _categories,
                selectedItem: _selectedCategory,
                onSelected: (val) => setState(() => _selectedCategory = val),
              ),
              const SectionHeader(title: '✨ Trending Near You', actionText: 'See all'),
              isLoading ? _buildGridShimmer() : ProductGridWidget(category: _selectedCategory),
              const SectionHeader(title: '📱 Community Feed'),
              isLoading ? _buildPostShimmer() : const CommunityPostCard(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => const ShimmerPlaceholder(width: 70, height: 70, borderRadius: 35, margin: EdgeInsets.only(right: 12)),
      ),
    );
  }

  Widget _buildLiveShimmer() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) => const ShimmerPlaceholder(width: 140, height: 180, borderRadius: 20, margin: EdgeInsets.only(right: 12)),
      ),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75),
        itemCount: 4,
        itemBuilder: (context, index) => const ShimmerPlaceholder(width: double.infinity, height: double.infinity, borderRadius: 16),
      ),
    );
  }

  Widget _buildPostShimmer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerPlaceholder(width: double.infinity, height: 200, borderRadius: 20),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Shop',
              style: AppTextStyles.h2.copyWith(color: AppColors.text, fontSize: 22),
              children: const [
                TextSpan(text: 'Near', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 12),
              const SizedBox(width: 4),
              Text(
                'Indore, Madhya Pradesh',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildIconBtn(Icons.notifications_none, true, () => context.push('/home/notifications')),
        const SizedBox(width: 8),
        _buildIconBtn(Icons.shopping_cart_outlined, false, () => context.push('/home/cart')),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, bool hasBadge, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.text),
            if (hasBadge)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: GestureDetector(
        onTap: () => context.go('/home/discover'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Search for your favorites...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.mic_none_rounded, color: AppColors.muted.withOpacity(0.5), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


