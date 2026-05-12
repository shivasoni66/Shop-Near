import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/reel_providers.dart';
import '../../../shared/models/reel.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        data: (reels) => PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            return _buildReelItem(reel);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildReelItem(Reel reel) {
    return Stack(
      children: [
        // Video Placeholder
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2B1B54), const Color(0xFF1A1D2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(reel.emoji ?? '🎬', style: const TextStyle(fontSize: 140)),
        ),
        
        // Dark Overlay at Bottom
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Right Side Actions
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              _buildReelAction(Icons.favorite, reel.likes.toString(), Colors.redAccent),
              const SizedBox(height: 20),
              _buildReelAction(Icons.chat_bubble, reel.comments.toString(), Colors.white),
              const SizedBox(height: 20),
              _buildReelAction(Icons.share, 'Share', Colors.white),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.push('/home/product/${reel.sellerId}'),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Text(reel.emoji ?? '👤')),
                  const SizedBox(width: 10),
                  Text(reel.sellerName, style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text('Follow', style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reel.description,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReelAction(IconData icon, String label, Color col) {
    return Column(
      children: [
        Icon(icon, color: col, size: 30),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}
