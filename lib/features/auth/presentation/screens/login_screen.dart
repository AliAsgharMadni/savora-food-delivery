import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_icons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(authControllerProvider.notifier).signInWithEmail(
              email: _emailController.text,
              password: _passwordController.text,
            );

    if (!success && mounted) {
      final errorState = ref.read(authControllerProvider);
      final errorMessage = errorState.error?.toString() ??
          'Failed to sign in. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleOAuth(OAuthProvider provider, String label) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$label sign-in requires OAuth configuration in Supabase Auth.'),
            backgroundColor: AppColors.inverseSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  // Culinary Header & Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(51),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: AppColors.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Savora',
                        style: TextStyle(
                          fontSize: 28,
                          height: 34 / 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.56,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Welcome Back Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed.withAlpha(102),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text(
                      'Welcome Back 👋',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.24,
                        color: AppColors.onSecondaryFixedVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Headline
                  const Text(
                    'Sign in to continue enjoying hot meals delivered fast',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 28 / 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.33,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subheading
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Text(
                      'Enter your registered credentials below to access your favorites and track orders in real-time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Login Card Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(32), // rounded-lg
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                hintText: 'you@domain.com',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!val.contains('@') ||
                                      !val.contains('.')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Label + Forgot Password?
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.24,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push(
                                      AppRoutes.forgotPassword,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 14 / 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              AuthTextField(
                                controller: _passwordController,
                                hintText: '••••••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              AuthButton(
                                text: 'Continue',
                                icon: Icons.arrow_forward,
                                isLoading: isLoading,
                                onPressed: _handleLogin,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Visual Food Teaser (Delight Anchor)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/images/pizza.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "CHEF'S SPECIAL",
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 14 / 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Truffle Burrata Rigatoni',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Ready in 20-30 mins',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 1,
                                width: double.infinity,
                                color: AppColors.surfaceVariant,
                              ),
                              Container(
                                color: AppColors.surfaceContainerLowest,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: const Text(
                                  'or sign in with',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.tertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Social Sign In Options
                        Row(
                          children: [
                            Expanded(
                              child: SocialAuthPillButton(
                                icon: const GoogleGIcon(size: 20),
                                label: 'Google',
                                onTap: () =>
                                    _handleOAuth(OAuthProvider.google, 'Google'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SocialAuthPillButton(
                                icon: const Icon(
                                  Icons.apple,
                                  size: 22,
                                  color: AppColors.onSurface,
                                ),
                                label: 'Apple',
                                onTap: () =>
                                    _handleOAuth(OAuthProvider.apple, 'Apple'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Account Switch Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.signup),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 14,
                            height: 18 / 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.14,
                            color: AppColors.primary,
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
    );
  }
}
