import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
      
      // The socket event will prepend the new reel automatically,
      // but call refresh as a safety net in case of missed events
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
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _uploadReel,
              child: Text('Post', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Caption Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),

          // Camera / Video Preview
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _selectedVideo != null && _videoController != null && _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_outlined, color: Colors.white, size: 64),
                            const SizedBox(height: 16),
                            Text('No video selected', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          
          // Gallery Toggle
          Padding(
            padding: const EdgeInsets.only(bottom: 40, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Select Video', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
