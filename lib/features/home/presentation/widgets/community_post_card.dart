import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/reel.dart';
import 'package:go_router/go_router.dart';

class CommunityPostCard extends StatefulWidget {
  final Reel reel;
  const CommunityPostCard({super.key, required this.reel});

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  bool _isLiked = false;
  late int _likesCount;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.reel.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likesCount++ : _likesCount--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(widget.reel.sellerName.isNotEmpty ? widget.reel.sellerName[0] : '👤', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.reel.sellerName, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
                      Text('Featured Store ✨', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz_rounded, color: AppColors.muted.withOpacity(0.5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              widget.reel.description,
              style: AppTextStyles.bodySmall.copyWith(height: 1.4),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/home/videos'),
            child: Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF2B1B54), Color(0xFF1A1D2E)]),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(widget.reel.emoji ?? '🎬', style: const TextStyle(fontSize: 64)),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: const Text('WATCH REEL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _buildActionItem(
                  icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  count: _likesCount.toString(),
                  color: _isLiked ? AppColors.primary : AppColors.text,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 18),
                _buildActionItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: widget.reel.comments.toString(),
                  color: AppColors.text,
                  onTap: () => context.push('/home/videos'),
                ),
                const SizedBox(width: 18),
                _buildActionItem(
                  icon: Icons.share_rounded,
                  count: 'Share',
                  color: AppColors.text,
                  onTap: () {},
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _isSaved ? AppColors.secondary : AppColors.text, size: 24),
                  onPressed: () {
                    setState(() => _isSaved = !_isSaved);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String count, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(count, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
