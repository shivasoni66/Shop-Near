import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_near/shared/providers/reel_providers.dart';
import 'package:shop_near/shared/providers/repository_providers.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/reel_providers.dart';

class PostReelScreen extends ConsumerStatefulWidget {
  const PostReelScreen({super.key});

  @override
  ConsumerState<PostReelScreen> createState() => _PostReelScreenState();
}

class _PostReelScreenState extends ConsumerState<PostReelScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedVideo;
  VideoPlayerController? _videoController;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideo = video;
        });
        _initializeVideoPlayer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController?.dispose();

    if (kIsWeb) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_selectedVideo!.path));
    } else {
      _videoController = VideoPlayerController.file(File(_selectedVideo!.path));
    }

    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();
    setState(() {});
  }

  Future<void> _uploadReel() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final repository = ref.read(reelRepositoryProvider);
      await repository.uploadReel(_selectedVideo!, _captionController.text.trim());

      await ref.read(reelsProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel posted successfully! 🎉')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reel: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Post Reel', style: AppTextStyles.h3),
        actions: [
          if (_selectedVideo != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadReel,
              child: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Post', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Video Preview
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _selectedVideo == null
                    ? InkWell(
                        onTap: _pickVideo,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined, color: Colors.white, size: 64),
                            const SizedBox(height: 16),
                            Text('Select Video from Gallery', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_videoController != null && _videoController!.value.isInitialized)
                              AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.change_circle, color: Colors.white, size: 32),
                                onPressed: _pickVideo,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Caption Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.card,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
