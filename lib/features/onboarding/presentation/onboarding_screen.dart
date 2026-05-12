import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animFloat;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _animFloat = Tween<double>(begin: 0, end: -12).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1D2E), Color(0xFF2D1B69), Color(0xFF0D1117)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animFloat,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _animFloat.value),
                      child: const Text('🛍️', style: TextStyle(fontSize: 88)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  RichText(
                    text: TextSpan(
                      text: 'Shop',
                      style: AppTextStyles.h1
                          .copyWith(color: Colors.white, fontSize: 34),
                      children: const [
                        TextSpan(
                            text: 'Near',
                            style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Local Sellers · Real Connections · Live Commerce',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Shop Live from Local Sellers',
                    style: AppTextStyles.h2
                        .copyWith(color: Colors.white, fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Discover unique products, watch live demos, and support your local community ecosystem 🌟',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white60, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('🛒 Get Started'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.3), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: AppTextStyles.labelLarge,
                      ),
                      child: const Text('🏪 Become a Seller →'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: Text(
                      'Already have an account? Sign In',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
