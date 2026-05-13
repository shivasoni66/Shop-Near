import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shop_near/features/auth/providers/auth_notifier.dart';
import 'package:shop_near/shared/providers/dynamic_product_providers.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/live_providers.dart';

class GoLiveSetupScreen extends ConsumerStatefulWidget {
  const GoLiveSetupScreen({super.key});

  @override
  ConsumerState<GoLiveSetupScreen> createState() => _GoLiveSetupScreenState();
}

class _GoLiveSetupScreenState extends ConsumerState<GoLiveSetupScreen> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'Fashion & Clothing 👗';
  bool _isLoading = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isVideoOn = true;
  bool _isMicOn = true;
  bool _isFrontCamera = true;
  FlashMode _flashMode = FlashMode.off;
  final Set<String> _pinnedProductIds = {};

  final List<String> _categories = [
    'Fashion & Clothing 👗',
    'Organic & Natural 🌿',
    'Food & Snacks 🍕',
    'Electronics & Gadgets 📱',
    'Handicrafts 🎨'
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({CameraDescription? specificCamera}) async {
    final status = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    if (status.isGranted && micStatus.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final camera = specificCamera ?? cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: true,
        );

        try {
          await _cameraController!.initialize();
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
              _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
            });
          }
        } catch (e) {
          debugPrint('Camera init error: $e');
        }
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameraController == null) return;
    final cameras = await availableCameras();
    final newLensDirection = _isFrontCamera ? CameraLensDirection.back : CameraLensDirection.front;
    final newCamera = cameras.firstWhere((cam) => cam.lensDirection == newLensDirection, orElse: () => cameras.first);
    
    await _cameraController?.dispose();
    setState(() => _isCameraInitialized = false);
    _initializeCamera(specificCamera: newCamera);
  }

  Future<void> _toggleVideo() async {
    if (_cameraController == null) return;
    if (_isVideoOn) {
      await _cameraController!.pausePreview();
    } else {
      await _cameraController!.resumePreview();
    }
    setState(() => _isVideoOn = !_isVideoOn);
  }

  Future<void> _toggleMic() async {
    // Note: Mic toggle usually happens at stream level, but we can set volume or re-init
    setState(() => _isMicOn = !_isMicOn);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> _startLive() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a session title')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(liveSessionRepositoryProvider);
      final session = await repository.startLiveSession(
        _titleController.text.trim(),
        _selectedCategory,
      );

      // Invalidate the provider so the buyer panel updates
      ref.invalidate(liveSessionsProvider);

      // IMPORTANT: Dispose the camera controller BEFORE navigating to LiveSessionScreen
      // to release the hardware lock so Agora can take over.
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      if (mounted) {
        context.pushReplacement('/home/live-session', extra: session);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException) {
        errorMsg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start live: $errorMsg')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/seller');
            }
          },
        ),
        title: Text('Go Live', style: AppTextStyles.h3),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('Setup',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCameraPreview(),
            _buildForm(),
            _buildPinProducts(),
            _buildLiveSettings(),
            _buildTipsBox(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildStartButton(context),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 10),
                Text(
                  'Initializing camera...',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          Positioned(
            bottom: 16,
            child: Row(
              children: [
                _buildCamCtrl(
                  _isVideoOn ? Icons.videocam : Icons.videocam_off, 
                  onTap: _toggleVideo,
                  isActive: _isVideoOn,
                ),
                const SizedBox(width: 16),
                _buildCamCtrl(
                  Icons.flip_camera_ios, 
                  onTap: _toggleCamera,
                  isActive: true,
                ),
                const SizedBox(width: 16),
                _buildCamCtrl(
                  _isMicOn ? Icons.mic : Icons.mic_off, 
                  onTap: _toggleMic,
                  isActive: _isMicOn,
                ),
                const SizedBox(width: 16),
                _buildCamCtrl(
                  _flashMode == FlashMode.torch ? Icons.lightbulb : Icons.lightbulb_outline, 
                  onTap: _toggleFlash,
                  isActive: _flashMode == FlashMode.torch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamCtrl(IconData icon, {required VoidCallback onTap, bool isActive = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.primary.withOpacity(0.8) : Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Session Title *', style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'e.g. New Saree Collection Launch 🌸',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Category', style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                items: _categories.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: AppTextStyles.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinProducts() {
    final user = ref.watch(authControllerProvider).user;
    final productsAsync = ref.watch(sellerProductsProvider(user?.id ?? ''));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pin Products to Live Session', style: AppTextStyles.labelLarge),
              Text('${_pinnedProductIds.length} pinned', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: productsAsync.when(
            data: (products) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length + 1,
              itemBuilder: (context, index) {
                if (index == products.length) return _buildAddProductBtn();
                final product = products[index];
                final isPinned = _pinnedProductIds.contains(product.id);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isPinned) {
                          _pinnedProductIds.remove(product.id);
                        } else {
                          _pinnedProductIds.add(product.id);
                        }
                      });
                    },
                    child: _buildPinnedProduct(
                      product.imagePlaceholder, 
                      product.name, 
                      '₹${product.price.toInt()}', 
                      isPinned
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading products')),
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedProduct(String imageUrl, String name, String price, bool isPinned) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isPinned ? AppColors.primary : AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(height: 4),
          Text(name,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
              overflow: TextOverflow.ellipsis),
          Text(price,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildAddProductBtn() {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline,
              color: AppColors.muted, size: 22),
          const SizedBox(height: 4),
          Text('Add More',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildLiveSettings() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Settings', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          _buildToggleTile('Enable Chat', 'Viewers can send messages', true),
          _buildToggleTile(
              'Show Product Prices', 'Visible during session', true),
          _buildToggleTile('Record Session', 'Save for later viewing', false),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String sub, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
              Text(sub,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
            ],
          ),
          Switch(
            value: value,
            onChanged: (_) {},
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        border: Border.all(color: AppColors.accent, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Tips for a Successful Live',
              style: AppTextStyles.labelLarge
                  .copyWith(color: const Color(0xFF92400E))),
          const SizedBox(height: 4),
          Text(
            '• Best time: 7–9 PM gets 3× more viewers\n• Show product close-ups and demo draping\n• Offer exclusive live-only discounts',
            style: AppTextStyles.bodySmall
                .copyWith(color: const Color(0xFF78350F), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _startLive,
        icon: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.sensors),
        label: Text(_isLoading ? 'Starting...' : 'Start Live Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.liveRed,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
