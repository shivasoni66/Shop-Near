import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/user_providers.dart';
import '../../../shared/models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _activeTabIndex = 0;
  final List<String> _tabs = ['Wishlist', 'Orders', 'Reviews', 'Badges'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: userAsync.when(
        data: (user) => FadeTransition(
          opacity: _fadeAnim,
          child: _buildProfileBody(user),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileBody(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          // ── Profile Cover ──
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 170,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B5FEF), Color(0xFF764ba2), Color(0xFFf093fb)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  top: -25, right: -30,
                  child: Container(width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                Positioned(
                  top: 80, left: -15,
                  child: Container(width: 60, height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
                  ),
                ),
                Positioned(
                  top: 14, right: 14,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => context.push('/home/settings'),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        gradient: const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
                        boxShadow: [BoxShadow(color: const Color(0xFFf093fb).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: (user.avatar ?? '').startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: user.avatar!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: Colors.white),
                              )
                            : Text(
                                (user.avatar ?? '').isNotEmpty ? user.avatar! : user.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 44, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Profile Info ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(user.name, style: AppTextStyles.h2.copyWith(fontSize: 21, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      '${user.handle ?? "@${user.name.replaceAll(" ", "_").toLowerCase()}"} · ${user.location ?? "Indore, MP"}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                Text(user.bio ?? 'Local shopping enthusiast 🛍️ Supporting local sellers!', textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('47', 'Orders', 1),
                      _buildDivider(),
                      _buildStat('128', 'Following', null),
                      _buildDivider(),
                      _buildStat('34', 'Reviews', 2),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/home/profile/edit'),
                        icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                        label: Text('Edit Profile', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3, shadowColor: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/seller'),
                        icon: Icon(Icons.storefront, size: 16, color: Theme.of(context).colorScheme.onSurface),
                        label: Text('Seller Mode', style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.border, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppColors.card,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Loyalty Card ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF4E6A), Color(0xFFFF7A90), Color(0xFFFFB199)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFFFF4E6A).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🏆 LOYALTY POINTS', style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('Silver', style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('1,240 pts', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                Text('260 pts away from Gold tier 🥇', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: 0.82, backgroundColor: Colors.white.withOpacity(0.25), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick Links ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: GestureDetector(onTap: () => setState(() => _activeTabIndex = 1), child: _buildQuickCard(Icons.local_shipping_outlined, 'My Orders', '47 orders', AppColors.secondary))),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(onTap: () => setState(() => _activeTabIndex = 0), child: _buildQuickCard(Icons.favorite_border, 'Wishlist', '12 items', AppColors.primary))),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Tabs ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(children: List.generate(_tabs.length, (i) => Expanded(child: _buildTab(_tabs[i], _activeTabIndex == i, i)))),
            ),
          ),

          const SizedBox(height: 14),

          AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return GridView.count(key: const ValueKey(0), crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), mainAxisSpacing: 12, crossAxisSpacing: 12, children: [
          _buildGridItem(context, '👗', const [Color(0xFFFFECD2), Color(0xFFFCB69F)]),
          _buildGridItem(context, '🌿', const [Color(0xFFA8EDEA), Color(0xFFFED6E3)]),
          _buildGridItem(context, '🎨', const [Color(0xFFD4FC79), Color(0xFF96E6A1)]),
          _buildGridItem(context, '💍', const [Color(0xFFF7797D), Color(0xFFFBD786)]),
          _buildGridItem(context, '📱', const [Color(0xFF667EEA), Color(0xFF764BA2)]),
          _buildGridItem(context, '🎀', const [Color(0xFFf093fb), Color(0xFFf5576c)]),
        ]);
      case 1:
        return ListView(key: const ValueKey(1), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          _buildOrderListItem(context, 'Silk Saree Blue', '#BL2048', 'Pending', AppColors.accent),
          _buildOrderListItem(context, 'Banarasi Dupatta', '#BL2047', 'Delivered', AppColors.success),
          _buildOrderListItem(context, 'Cotton Kurti Set', '#BL2046', 'Delivered', AppColors.success),
        ]);
      case 2:
        return ListView(key: const ValueKey(2), shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          _buildReviewItem('Priya Fashion', 'Great quality saree! The fabric is very soft and the color is exactly as shown in the live session.', 5),
          _buildReviewItem('Green Bazaar', 'Fresh organic honey. Delivery was quick and packaging was eco-friendly.', 4),
        ]);
      case 3:
        return GridView.count(key: const ValueKey(3), crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16), mainAxisSpacing: 10, crossAxisSpacing: 10, children: [
          _buildBadgeItem('🌟', 'Top Buyer'), _buildBadgeItem('🔥', 'Early Adopter'), _buildBadgeItem('🤝', 'Local Supporter'), _buildBadgeItem('💎', 'Premium'),
        ]);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOrderListItem(BuildContext context, String name, String id, String status, Color color) {
    return GestureDetector(
      onTap: () => context.push('/home/order-track'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.secondary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)]), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: const Text('🛍️', style: TextStyle(fontSize: 20))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)), Text(id, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w900))),
        ]),
      ),
    );
  }

  Widget _buildReviewItem(String shop, String review, int stars) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(shop, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          Row(children: List.generate(stars, (i) => const Icon(Icons.star, color: AppColors.accent, size: 14))),
        ]),
        const SizedBox(height: 6),
        Text(review, style: AppTextStyles.bodySmall.copyWith(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }

  Widget _buildBadgeItem(String emoji, String label) {
    return Column(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle, border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))]),
        alignment: Alignment.center, child: Text(emoji, style: const TextStyle(fontSize: 26))),
      const SizedBox(height: 5),
      Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center),
    ]);
  }

  Widget _buildStat(String val, String lbl, int? tabIndex) {
    return GestureDetector(
      onTap: tabIndex != null ? () => setState(() => _activeTabIndex = tabIndex) : null,
      child: Column(children: [
        Text(val, style: AppTextStyles.h3.copyWith(fontSize: 19, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 2),
        Text(lbl, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11)),
      ]),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: AppColors.border);
  }

  Widget _buildQuickCard(IconData icon, String title, String sub, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center, child: Icon(icon, color: iconColor, size: 22)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.labelMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          Text(sub, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildTab(String text, bool active, int index) {
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? AppColors.text : Colors.transparent, width: 2.5)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.text : AppColors.muted,
            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String emoji, List<Color> gradient) {
    return GestureDetector(
      onTap: () => context.push('/home/product/1'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 34)),
      ),
    );
  }
}
