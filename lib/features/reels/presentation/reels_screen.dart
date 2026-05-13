import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/reel_providers.dart';
import '../../../shared/models/reel.dart';
import '../../../shared/providers/repository_providers.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../features/auth/providers/auth_notifier.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showReelOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Create New Reel', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('Showcase your products to thousands!', style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.videocam_rounded,
                  label: 'Camera',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/seller/post-reel?source=camera');
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/seller/post-reel?source=gallery');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 10),
          Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, Reel reel) {
    final commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('${reel.comments} Comments', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10, height: 32),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final commentsAsync = ref.watch(reelCommentsProvider(reel.id));
                  return commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return const Center(child: Text('No comments yet. Be the first! 💬', style: TextStyle(color: Colors.white38)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final user = comment['user'] is Map ? comment['user'] : null;
                          return _buildCommentItem(
                            user?['name'] ?? 'User',
                            comment['text'] ?? '',
                            'Just now', // Mock time for now
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Center(child: Text('Error loading comments', style: TextStyle(color: Colors.redAccent.withOpacity(0.7)))),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      if (commentController.text.trim().isNotEmpty) {
                        await ref.read(reelRepositoryProvider).commentOnReel(reel.id, commentController.text.trim());
                        ref.invalidate(reelCommentsProvider(reel.id));
                        commentController.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment added! 💬')));
                        }
                      }
                    },
                    child: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(String name, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.white10, child: Text(name.isNotEmpty ? name[0] : '👤', style: const TextStyle(color: Colors.white, fontSize: 10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 16),
                    const Text('Reply', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_border, color: Colors.white38, size: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsProvider);
    final user = ref.watch(authControllerProvider).user;
    final isSeller = user?.role == 'seller';

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎬', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No reels available yet', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70)),
                ],
              ),
            );
          }
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              return _buildReelItem(reels[index], true);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton: isSeller ? FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 36),
        onPressed: () => _showReelOptions(context),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildReelItem(Reel reel, bool isActive) {
    final user = ref.watch(authControllerProvider).user;
    final isLiked = reel.likesList.contains(user?.id);

    return Stack(
      children: [
        Positioned.fill(
          child: ReelVideoPlayer(videoUrl: reel.videoUrl, emoji: reel.emoji, isActive: isActive),
        ),
        
        // Premium Overlays
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.2, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Right Side Actions (Glassmorphism inspired)
        Positioned(
          right: 12,
          bottom: 110,
          child: Column(
            children: [
              _buildReelAction(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                label: reel.likes.toString(), 
                col: isLiked ? Colors.redAccent : Colors.white,
                onTap: () => ref.read(reelRepositoryProvider).likeReel(reel.id),
              ),
              const SizedBox(height: 18),
              _buildReelAction(
                icon: Icons.chat_bubble_outline_rounded, 
                label: reel.comments.toString(), 
                col: Colors.white,
                onTap: () => _showComments(context, reel),
              ),
              const SizedBox(height: 18),
              _buildReelAction(
                icon: Icons.ios_share_rounded, 
                label: 'Share', 
                col: Colors.white, 
                onTap: () => Share.share('Check out this amazing reel on ShopNear: ${reel.videoUrl}'),
              ),
              const SizedBox(height: 24),
              _buildProductShortcut(reel),
            ],
          ),
        ),

        // Bottom Info Panel
        Positioned(
          left: 16,
          bottom: 30,
          right: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(reel.sellerName.isNotEmpty ? reel.sellerName[0] : 'U', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reel.sellerName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text('Certified Seller ✨', style: TextStyle(color: AppColors.accent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.music_note_rounded, color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text('Original Audio', style: TextStyle(color: Colors.white, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reel.description,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductShortcut(Reel reel) {
    return GestureDetector(
      onTap: () => context.push('/home/product/${reel.sellerId}'),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10)],
            ),
          ),
          const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildReelAction({
    required IconData icon, 
    required String label, 
    required Color col,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: col),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? emoji;
  final bool isActive;

  const ReelVideoPlayer({super.key, required this.videoUrl, this.emoji, this.isActive = false});

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  String get _resolvedUrl {
    final videoUrl = widget.videoUrl;
    if (videoUrl.isEmpty) return '';
    final uri = Uri.tryParse(videoUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return videoUrl;
    }
    final rel = videoUrl.startsWith('/') ? videoUrl.substring(1) : videoUrl;
    final baseUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
    return '$baseUrl/$rel';
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (_controller != null && _initialized) {
        if (widget.isActive) {
          _controller!.play();
        } else {
          _controller!.pause();
        }
      }
    }
  }

  Future<void> _initPlayer() async {
    final url = _resolvedUrl;
    if (url.isEmpty) {
      setState(() => _error = true);
      return;
    }
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (widget.isActive) {
        _controller!.play();
      }
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      debugPrint('VideoPlayer error: $e | URL: $url');
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;

    if (_error || url.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B1B54), Color(0xFF1A1D2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(widget.emoji ?? '🎬', style: const TextStyle(fontSize: 140)),
      );
    }

    if (!_initialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
