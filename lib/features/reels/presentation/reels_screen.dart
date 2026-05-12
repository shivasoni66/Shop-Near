import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/reel_providers.dart';
import '../../../shared/models/reel.dart';
import '../../../shared/providers/repository_providers.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/api_endpoints.dart';
// Removed web-only imports to fix mobile build


class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure socket is connected when the reels screen opens
    Future.microtask(() {
      ref.read(socketServiceProvider).connect();
    });
  }

  Future<void> _refresh() => ref.read(reelsProvider.notifier).refresh();

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

  Widget _buildReelItem(Reel reel, bool isActive) {
    return Stack(
      children: [
        // Actual Video Player
        Positioned.fill(
          child: ReelVideoPlayer(videoUrl: reel.videoUrl, emoji: reel.emoji, isActive: isActive),
        ),
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
                icon: Icons.chat_bubble, 
                label: reel.comments.toString(), 
                col: Colors.white,
                onTap: () {
                  _showComments(context, reel.id);
                },
              ),
              _buildReelAction(Icons.favorite, reel.likes.toString(), Colors.redAccent),
              const SizedBox(height: 20),
              _buildReelAction(Icons.chat_bubble, reel.comments.toString(), Colors.white),
              const SizedBox(height: 20),
              _buildReelAction(icon: Icons.share, label: 'Share', col: Colors.white, onTap: () {}),
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

  void _showComments(BuildContext context, String reelId) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Comments', style: AppTextStyles.h3.copyWith(color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ref.read(reelRepositoryProvider).getReelComments(reelId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading comments', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)));
                    }
                    final comments = snapshot.data ?? [];
                    if (comments.isEmpty) {
                      return Center(child: Text('No comments yet', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white54)));
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final user = comment['user'] ?? {};
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(user['avatar'] ?? '👤', style: const TextStyle(fontSize: 16)),
                          ),
                          title: Text(user['name'] ?? 'User', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                          subtitle: Text(comment['text'] ?? '', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isNotEmpty) {
                        try {
                          await ref.read(reelRepositoryProvider).commentOnReel(reelId, text);
                          commentController.clear();
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          // It will auto-refresh comments when reopened because the socket updates the reel state
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
                        }
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReelAction({required IconData icon, required String label, required Color col, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: col, size: 30),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: Colors.white, fontSize: 11)),
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
  // Mobile only
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  // Web only
  late final String _viewId;
  html.VideoElement? _webVideoElement;

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
      if (kIsWeb) {
        if (widget.isActive) {
          _webVideoElement?.play();
        } else {
          _webVideoElement?.pause();
        }
      } else {
        if (_controller != null && _initialized) {
          if (widget.isActive) {
            _controller!.play();
          } else {
            _controller!.pause();
          }
        }
      }
    }
  }

  void _registerWebVideo() {
    final url = _resolvedUrl;
    if (url.isEmpty) {
      setState(() => _error = true);
      return;
    }

    final videoEl = html.VideoElement()
      ..src = url
      ..autoplay = widget.isActive
      ..loop = true
      ..muted = false
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.pointerEvents = 'none' // Allow GestureDetector to handle taps on Web
      ..setAttribute('playsinline', '')
      ..setAttribute('crossorigin', 'anonymous');

    _webVideoElement = videoEl;

    videoEl.onError.listen((_) {
      debugPrint('HTML video error for: $url');
      if (mounted) setState(() => _error = true);
    });
    videoEl.onCanPlay.listen((_) {
      if (widget.isActive) {
        videoEl.play();
      }
    });

    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) => videoEl);
    setState(() {});
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

    if (!kIsWeb && (!_initialized || _controller == null)) {

    if (!_initialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        if (kIsWeb) {
          if (_webVideoElement != null) {
            if (_webVideoElement!.paused) {
              _webVideoElement!.play();
            } else {
              _webVideoElement!.pause();
            }
          }
        } else {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        }
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: kIsWeb 
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: HtmlElementView(viewType: _viewId),
              )
            : SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
        ),
      ),
    );
  }
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
