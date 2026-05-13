import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  final String currentRoute;

  const AppBottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Row(
        children: [
          _buildNavItem(context, 'Home', Icons.home_filled, Icons.home_outlined, '/home'),
          _buildNavItem(context, 'Videos', Icons.video_collection, Icons.video_collection_outlined, '/home/videos'),
          _buildLiveNavBtn(context),
          _buildNavItem(context, 'Cart', Icons.shopping_cart, Icons.shopping_cart_outlined, '/home/cart'),
          _buildNavItem(context, 'Profile', Icons.person, Icons.person_outline, '/home/profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData activeIcon, IconData inactiveIcon, String route) {
    final isActive = currentRoute == route;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isActive) context.go(route);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : AppColors.muted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveNavBtn(BuildContext context) {
    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: () => context.push('/home/live'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -18),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.sensors, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'LIVE',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
