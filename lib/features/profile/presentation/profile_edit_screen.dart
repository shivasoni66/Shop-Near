import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/providers/user_providers.dart';
import '../../../shared/models/user.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillData();
    });
  }

  void _prefillData() {
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _handleController.text = user.handle ?? '';
      _locationController.text = user.location ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.updateProfile({
        'name': _nameController.text,
        'handle': _handleController.text,
        'location': _locationController.text,
        'bio': _bioController.text,
      }, imagePath: _imageFile?.path);

      ref.invalidate(userProfileProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.value;

    // Listen for data changes to prefill if it was loading initially
    ref.listen<AsyncValue<User>>(userProfileProvider, (previous, next) {
      if (previous?.value == null && next.value != null) {
        _prefillData();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.border,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : ((user?.avatar ?? '').isNotEmpty
                            ? NetworkImage(user!.avatar!)
                            : null) as ImageProvider?,
                    child: (_imageFile == null && (user?.avatar ?? '').isEmpty)
                        ? const Icon(Icons.person, size: 60, color: AppColors.muted)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField('Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField('Handle (e.g. @priya_sarees)', _handleController, Icons.alternate_email),
            const SizedBox(height: 16),
            _buildTextField('Location', _locationController, Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildTextField('Bio', _bioController, Icons.info_outline, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.muted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            cursorColor: Colors.black,
            style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              icon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              hintText: 'Enter $label',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.muted.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
