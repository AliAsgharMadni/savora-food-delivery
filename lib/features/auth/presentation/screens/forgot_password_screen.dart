import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text);

    if (mounted) {
      if (success) {
        setState(() {
          _emailSent = true;
        });
      } else {
        final errorState = ref.read(authControllerProvider);
        final errorMessage = errorState.error?.toString() ??
            'Failed to send reset link. Please check the email and try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
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
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scroll Content (with top clearance for frosted 64px header)
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, safeTop + 64 + 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Layered Glow Icon Badge + Floating Key Badge
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient Glow Halo
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.secondaryContainer.withAlpha(115),
                                  AppColors.secondaryContainer.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                          // Outer White Tactile Ring + Inner Circle
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(26),
                                  blurRadius: 15,
                                  spreadRadius: -3,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(15),
                                  blurRadius: 6,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_reset,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          // Floating Bottom-Right Key Tag
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(38),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.key,
                                color: AppColors.onPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Headline
                    const Text(
                      'Reset Password 🔑',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        height: 34 / 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.56,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subheading constrained to 280px
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: const Text(
                        "Enter the email associated with your Savora account and we'll send you a link to reset your password.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset Request Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(32), // rounded-lg
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(13),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AuthTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hintText: 'name@example.com',
                                  prefixIcon: Icons.mail_outline,
                                  prefixIconColor: AppColors.primary,
                                  keyboardType: TextInputType.emailAddress,
                                  focusedFillColor: AppColors.surfaceContainer,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!val.contains('@') ||
                                        !val.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Main Action Pill Button (h-13 = 52px)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isLoading ? null : _handleReset,
                                    borderRadius: BorderRadius.circular(9999),
                                    child: Ink(
                                      width: double.infinity,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: isLoading
                                            ? AppColors.primary.withAlpha(190)
                                            : AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(9999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withAlpha(64), // 0.25
                                            blurRadius: 10,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: isLoading
                                            ? const [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.onPrimary,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Sending...',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onPrimary,
                                                  ),
                                                ),
                                              ]
                                            : [
                                                Text(
                                                  _emailSent
                                                      ? 'Resend Link'
                                                      : 'Send Reset Link',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 18 / 14,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.14,
                                                    color: AppColors.onPrimary,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  _emailSent
                                                      ? Icons.refresh
                                                      : Icons.arrow_forward,
                                                  size: 18,
                                                  color: AppColors.onPrimary,
                                                ),
                                              ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dynamic Feedback Confirmation Banner
                          if (_emailSent) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed.withAlpha(128),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read,
                                      color: AppColors.onPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Link Sent Successfully!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.24,
                                      color: AppColors.onSecondaryFixed,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please check your inbox and tap the link within 15 minutes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.onSecondaryFixedVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Helpful Context Callout ("Didn't receive an email?")
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed.withAlpha(77),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Didn't receive an email? Check your spam folder or try another email address linked to your account.",
                              style: TextStyle(
                                fontSize: 12,
                                height: 19.5 / 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSecondaryFixedVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Secondary Navigation Action ("Remember your password? Back to Login")
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.login),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.24,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Frosted Top Header (h-16 = 64px)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(top: safeTop),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(204),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go(AppRoutes.login),
                                borderRadius: BorderRadius.circular(9999),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 24,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Forgot Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 24 / 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.18,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Need help? Contact support@savora.app',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(9999),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.more_vert,
                                size: 24,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
