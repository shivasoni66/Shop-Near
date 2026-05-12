import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          ),
          ResolutionPreset.medium,
        );

        try {
          await _cameraController!.initialize();
          if (mounted) {
            setState(() => _isCameraInitialized = true);
          }
        } catch (e) {
          debugPrint('Camera init error: $e');
        }
      }
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

      if (mounted) {
        context.push('/home/live-session', extra: session);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start live: ${e.toString()}')),
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
                _buildCamCtrl(Icons.videocam_off),
                const SizedBox(width: 16),
                _buildCamCtrl(Icons.flip_camera_ios),
                const SizedBox(width: 16),
                _buildCamCtrl(Icons.mic),
                const SizedBox(width: 16),
                _buildCamCtrl(Icons.lightbulb_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCamCtrl(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
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
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'e.g. New Saree Collection Launch 🌸',
              hintStyle:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Category', style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Pin Products to Live Session',
              style: AppTextStyles.labelLarge),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildPinnedProduct('👗', 'Silk Saree', '₹1,299', true),
              const SizedBox(width: 10),
              _buildPinnedProduct('🧣', 'Dupatta', '₹850', true),
              const SizedBox(width: 10),
              _buildAddProductBtn(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedProduct(
      String icon, String name, String price, bool isPinned) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isPinned ? AppColors.primary : AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
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
