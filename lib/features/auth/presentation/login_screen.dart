import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';
import '../providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Clear any previous error when entering the screen
    Future.microtask(() => ref.read(authControllerProvider.notifier).clearError());
    
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.65, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    await ref.read(authControllerProvider.notifier).login(email, password);
    
    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage ?? 'Login failed'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (authState.status == AuthStatus.authenticated) {
        final role = authState.user?.role;
        if (role == 'seller') {
          context.go('/seller');
        } else {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1D2E), Color(0xFF0D1117)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 450 : double.infinity,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                                ],
                              ),
                              child: const Icon(
                                Icons.local_mall_rounded,
                                size: 64,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Welcome Back!',
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: isDesktop ? 40 : 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to continue shopping near you',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!value.contains('@')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.5)),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(authControllerProvider.notifier).clearError();
                                  context.push('/register');
                                },
                                child: Text(
                                  'Register Now',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}
