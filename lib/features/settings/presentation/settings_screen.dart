import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../../shared/providers/user_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Row
            userAsync.when(
              data: (user) => Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.card,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user.avatar ?? '').isNotEmpty ? user.avatar![0].toUpperCase() : '😊', 
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: AppTextStyles.labelLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w900)),
                          Text('${user.handle ?? "@user"} · Silver Member', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SizedBox(),
            ),
            const SizedBox(height: 8),

            _buildSection('ACCOUNT', [
              _buildSettingsItem(context, Icons.person, const Color(0xFFFFF0F3), AppColors.primary, 'Edit Profile', 'Name, photo, bio, location', true),
              _buildSettingsItem(context, Icons.phone, const Color(0xFFEFF6FF), AppColors.secondary, 'Phone & Email', '+91 98765 43210', true),
              _buildSettingsItem(context, Icons.location_on, const Color(0xFFECFDF5), AppColors.success, 'Saved Addresses', '3 addresses saved', true),
              _buildSettingsItem(context, Icons.credit_card, const Color(0xFFFFF9EC), AppColors.accent, 'Payment Methods', '2 UPI · 1 Card saved', true),
            ]),

            const SizedBox(height: 8),

            _buildSection('NOTIFICATIONS', [
              _buildToggleItem(context, Icons.live_tv, const Color(0xFFFFF0F3), AppColors.live, 'Live Session Alerts', 'When sellers you follow go live', true),
              _buildToggleItem(context, Icons.shopping_bag, const Color(0xFFECFDF5), AppColors.success, 'Order Updates', 'Dispatch, delivery notifications', true),
              _buildToggleItem(context, Icons.local_offer, const Color(0xFFFFF9EC), AppColors.accent, 'Offers & Deals', 'Flash sales, promo codes', true),
              _buildToggleItem(context, Icons.chat_bubble, const Color(0xFFEFF6FF), AppColors.secondary, 'Chat Messages', 'New messages from sellers', false),
            ]),

            const SizedBox(height: 8),

            _buildSection('PRIVACY & SECURITY', [
              _buildSettingsItem(context, Icons.shield, const Color(0xFFFFF0F3), AppColors.primary, 'Privacy Settings', 'Control who sees your activity', true),
              _buildToggleItem(context, Icons.fingerprint, const Color(0xFFECFDF5), AppColors.success, 'Biometric Login', 'Use fingerprint or Face ID', true),
              _buildSettingsItem(context, Icons.key, const Color(0xFFFFF9EC), AppColors.accent, 'Change Password', 'Last changed 30 days ago', true),
            ]),

            const SizedBox(height: 8),

            _buildSection('SUPPORT', [
              _buildSettingsItem(context, Icons.headset_mic, const Color(0xFFEFF6FF), AppColors.secondary, 'Help & Support', 'FAQs, contact us', true),
              _buildSettingsItem(context, Icons.star_outline, const Color(0xFFFFF9EC), AppColors.accent, 'Rate the App', 'Share your feedback', true),
              _buildLogoutItem(context, ref),
            ]),

            const SizedBox(height: 16),
            Text('ShopNear v2.5.0 · Made with ❤️ for Local India', textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, Color iconBg, Color iconColor, String label, String sub, bool hasChevron) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label settings coming soon! ⚙️')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(sub, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            if (hasChevron) const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, IconData icon, Color iconBg, Color iconColor, String label, String sub, bool toggled) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label preference updated! 🔔')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(sub, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: toggled ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(2),
              alignment: toggled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) {
          context.go('/');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: const Color(0xFFFFF0F3), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Icon(Icons.logout, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log Out', style: AppTextStyles.labelMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  Text('End your session', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
