import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/reel_providers.dart';
import '../../../shared/models/reel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/api_endpoints.dart';
import 'package:flutter/foundation.dart';


class ReelsScreen extends ConsumerStatefulWidget {
  final String? emoji;
  const ReelsScreen({super.key, this.emoji});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(reelsProvider.notifier).refresh();
  }

  void _showComments(BuildContext context, String reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Comments', style: AppTextStyles.h3),
              const Expanded(
                child: Center(child: Text('Comments feature coming soon!')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, size: 80, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text('No reels yet', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Be the first to post one!', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.white,
            backgroundColor: Colors.black54,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: reels.length,
              itemBuilder: (context, index) {
                final reel = reels[index];
                return _buildReelItem(reel, index == _currentIndex);
              },
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => context.push('/seller/post-reel'),
      ),
    );
  }

  Widget _buildReelItem(Reel reel, bool isActive) {
    return Stack(
      children: [
        // Actual Video Player
        // 1. Video Placeholder (Bottom Layer)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A1D2E), const Color(0xFF0D1117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(reel.emoji ?? '🎬', style: const TextStyle(fontSize: 120, color: Colors.white10)),
        ),

        // 2. Actual Video Player (Middle Layer)
        Positioned.fill(
          child: ReelVideoPlayer(videoUrl: reel.videoUrl, emoji: reel.emoji, isActive: isActive),
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
              _buildReelAction(
                icon: Icons.favorite, 
                label: reel.likes.toString(), 
                col: Colors.redAccent,
                onTap: () {
                  ref.read(reelRepositoryProvider).likeReel(reel.id);
                },
              ),
              const SizedBox(height: 20),
              _buildReelAction(
                icon: Icons.chat_bubble_rounded, 
                label: reel.comments.toString(), 
                col: Colors.white,
                onTap: () {
                  _showComments(context, reel.id);
                },
              ),
              const SizedBox(height: 20),
              _buildReelAction(icon: Icons.share_rounded, label: 'Share', col: Colors.white, onTap: () {}),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.push('/home/product/${reel.sellerId}'),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          bottom: 40,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(reel.sellerName[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    reel.sellerName,
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reel.description,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Original Audio - ${reel.sellerName}',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Icon(icon, color: col, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
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
    // Relative path — strip leading slash to avoid double slash
    final rel = videoUrl.startsWith('/') ? videoUrl.substring(1) : videoUrl;
    // Use the base URL from ApiEndpoints
    final baseUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
    return '$baseUrl/$rel';
  }

  @override
  void initState() {
    super.initState();
    _initMobilePlayer();
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

  Future<void> _initMobilePlayer() async {
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
