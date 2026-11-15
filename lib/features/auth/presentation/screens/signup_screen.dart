import 'package:flutter/gestures.dart';
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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _strengthScore = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String val) {
    if (val.isEmpty) {
      setState(() => _strengthScore = 0);
      return;
    }
    int score = 0;
    if (val.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(val)) score++;
    if (RegExp(r'[0-9]').hasMatch(val)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(val)) score++;
    setState(() => _strengthScore = score == 0 ? 1 : score);
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(authControllerProvider.notifier).signUpWithEmail(
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _nameController.text,
            );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Welcome to Savora.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final errorState = ref.read(authControllerProvider);
        final errorMessage = errorState.error?.toString() ??
            'Registration failed. Please try again.';
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

  Future<void> _handleOAuth(OAuthProvider provider, String label) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$label sign-up requires OAuth configuration in Supabase Auth.'),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtle Culinary Visual Header Badge & Brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Savora',
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingDot(),
                            SizedBox(width: 6),
                            Text(
                              'Live Kitchens',
                              style: TextStyle(
                                fontSize: 10,
                                height: 14 / 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Warm Editorial Intro
                  const Text(
                    'Create Your Account ✨',
                    style: TextStyle(
                      fontSize: 28,
                      height: 34 / 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.56,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join thousands enjoying fresh food delivered hot from local kitchens.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 22.75 / 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Micro Social Proof Snippet
                  Container(
                    padding: const EdgeInsets.all(14),
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
                    child: const Row(
                      children: [
                        _OverlappingAvatars(),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loved by 42,000+ local foodies',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.24,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '4.9/5 satisfaction rate this week',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 14 / 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Registration Form Fields (directly on #FFF8F1 canvas)
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hintText: 'e.g. Bilal Tariq',
                          prefixIcon: Icons.person_outline,
                          prefixIconColor: AppColors.outline,
                          unfocusedFillColor: AppColors.surfaceContainerLowest,
                          focusedFillColor: AppColors.surfaceContainerLow,
                          useCardShadow: true,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        AuthTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: Icons.alternate_email,
                          prefixIconColor: AppColors.outline,
                          keyboardType: TextInputType.emailAddress,
                          unfocusedFillColor: AppColors.surfaceContainerLowest,
                          focusedFillColor: AppColors.surfaceContainerLow,
                          useCardShadow: true,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Label + Live Strength Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            _StrengthLabel(score: _strengthScore),
                          ],
                        ),
                        const SizedBox(height: 6),

                        AuthTextField(
                          controller: _passwordController,
                          hintText: 'At least 8 characters',
                          prefixIcon: Icons.lock_outline,
                          prefixIconColor: AppColors.outline,
                          obscureText: _obscurePassword,
                          unfocusedFillColor: AppColors.surfaceContainerLowest,
                          focusedFillColor: AppColors.surfaceContainerLow,
                          useCardShadow: true,
                          onChanged: _updatePasswordStrength,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.outline,
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
                              return 'Please enter a password';
                            }
                            if (val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),

                        // Password Strength Visual Bar (4 segments)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(4, (idx) {
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: idx < 3 ? 6 : 0),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _barColorForSegment(
                                              idx, _strengthScore),
                                          borderRadius:
                                              BorderRadius.circular(9999),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Mix uppercase, numbers, and symbols for a stronger lock.',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 14 / 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms & Policies Disclaimer
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                height: 19.5 / 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(
                                    text: 'By signing up, you agree to Savora '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Savora Terms of Service accepted.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Savora Privacy Policy reviewed.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary CTA Button
                        AuthButton(
                          text: 'Create Account',
                          icon: Icons.arrow_forward,
                          isLoading: isLoading,
                          onPressed: _handleSignup,
                        ),
                      ],
                    ),
                  ),

                  // Divider Break ("OR CONTINUE WITH")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: AppColors.surfaceContainerHigh,
                        ),
                        Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(
                              fontSize: 10,
                              height: 14 / 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Social Authentication Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: SocialAuthPillButton(
                          icon: const GoogleGIcon(size: 20),
                          label: 'Google',
                          backgroundColor: AppColors.surfaceContainerLowest,
                          textColor: AppColors.onSurface,
                          hasShadow: true,
                          onTap: () =>
                              _handleOAuth(OAuthProvider.google, 'Google'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SocialAuthPillButton(
                          icon: const Icon(
                            Icons.apple,
                            size: 20,
                            color: AppColors.inverseOnSurface,
                          ),
                          label: 'Apple',
                          backgroundColor: AppColors.inverseSurface,
                          textColor: AppColors.inverseOnSurface,
                          hasShadow: true,
                          onTap: () =>
                              _handleOAuth(OAuthProvider.apple, 'Apple'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Footer Prompt
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: const Text(
                            'Log in',
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _barColorForSegment(int index, int score) {
    if (score == 0 || index >= score) {
      return AppColors.surfaceContainerHigh;
    }
    if (score == 1 || score >= 4) {
      return AppColors.primary;
    }
    return AppColors.secondaryContainer;
  }
}

class _StrengthLabel extends StatelessWidget {
  final int score;
  const _StrengthLabel({required this.score});

  @override
  Widget build(BuildContext context) {
    String text = 'Must be 8+ chars';
    Color color = AppColors.onSurfaceVariant;
    FontWeight weight = FontWeight.w700;

    if (score == 1) {
      text = 'Weak';
      color = AppColors.primary;
    } else if (score == 2) {
      text = 'Moderate';
      color = AppColors.secondary;
    } else if (score == 3) {
      text = 'Good';
      color = AppColors.secondary;
    } else if (score >= 4) {
      text = 'Strong ✨';
      color = AppColors.primary;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        height: 14 / 10,
        fontWeight: weight,
        letterSpacing: 0.4,
        color: color,
      ),
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars();

  @override
  Widget build(BuildContext context) {
    const urls = [
      'assets/images/pizza.png',
      'assets/images/biryani.png',
      'assets/images/burger.png',
    ];
    return SizedBox(
      width: 72,
      height: 32,
      child: Stack(
        children: List.generate(urls.length, (i) {
          return Positioned(
            left: i * 20.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceContainerLowest,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(urls[i], fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

