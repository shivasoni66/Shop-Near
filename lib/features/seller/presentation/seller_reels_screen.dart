import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/reel_providers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/models/reel.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class SellerReelsScreen extends ConsumerWidget {
  const SellerReelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reelsAsync = ref.watch(sellerReelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Reels', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library_outlined, size: 64, color: AppColors.muted),
                  const SizedBox(height: 16),
                  Text('You haven\'t posted any reels yet.', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/seller/post-reel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Post a Reel'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(sellerReelsProvider.future),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.56, // roughly 9:16 aspect ratio
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: reels.length,
              itemBuilder: (context, index) {
                return _SellerReelCard(reel: reels[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _SellerReelCard extends ConsumerWidget {
  final Reel reel;

  const _SellerReelCard({required this.reel});

  void _editCaption(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: reel.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Edit Caption', style: AppTextStyles.h3),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Enter new caption...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCaption = controller.text.trim();
              if (newCaption.isNotEmpty && newCaption != reel.description) {
                Navigator.pop(context);
                try {
                  await ref.read(reelRepositoryProvider).editReelCaption(reel.id, newCaption);
                  ref.invalidate(sellerReelsProvider);
                  ref.read(reelsProvider.notifier).refresh(); // Update main feed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caption updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteReel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete Reel', style: AppTextStyles.h3),
        content: const Text('Are you sure you want to delete this reel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(reelRepositoryProvider).deleteReel(reel.id);
                ref.invalidate(sellerReelsProvider);
                ref.read(reelsProvider.notifier).refresh(); // Update main feed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reel deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MiniVideoPlayer(videoUrl: reel.videoUrl),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.description,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('${reel.likes}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chat_bubble, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('${reel.comments}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCaption(context, ref);
                  } else if (value == 'delete') {
                    _deleteReel(context, ref);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Caption')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _MiniVideoPlayer({required this.videoUrl});

  @override
  State<_MiniVideoPlayer> createState() => _MiniVideoPlayerState();
}

class _MiniVideoPlayerState extends State<_MiniVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  late final String _viewId;

  String get _resolvedUrl {
    final url = widget.videoUrl;
    if (url.startsWith('http')) return url;
    final rel = url.startsWith('/') ? url.substring(1) : url;
    return 'http://localhost:5000/$rel';
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(_resolvedUrl))
      ..initialize().then((_) {
        _controller!.setLooping(true);
        _controller!.setVolume(0.0); // Muted by default
        _controller!.play();
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator()));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
