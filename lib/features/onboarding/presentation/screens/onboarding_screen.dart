import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';

const _kOnboardingKey = 'has_seen_onboarding';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loadingAction = false;
  bool _loadingSkip = false;

  static const _slides = [
    _OnboardingSlide(
      imageAsset: 'assets/images/pizza.png',
      leftChip: 'Savora Kitchens',
      rightChip: 'Freshly Baked',
      ambientBadge: 'Artisan Quality',
      headline: 'Good food, right at your door.',
      subtext: 'Fresh meals from local kitchens, delivered hot.',
    ),
    _OnboardingSlide(
      imageAsset: 'assets/images/biryani.png',
      leftChip: 'Savora Kitchens',
      rightChip: 'Freshly Prepared',
      ambientBadge: 'Chef Craftsmanship',
      headline: 'Good food, right at your door.',
      subtext: 'Fresh meals from local kitchens, delivered hot.',
    ),
    _OnboardingSlide(
      imageAsset: 'assets/images/burger.png',
      leftChip: 'Savora Kitchens',
      rightChip: 'Fast Courier',
      ambientBadge: 'Live Tracking',
      headline: 'Good food, right at your door.',
      subtext: 'Fresh meals from local kitchens, delivered hot.',
    ),
  ];

  Future<void> _completeOnboarding({bool fromSkip = false}) async {
    if (_loadingAction || _loadingSkip) return;
    setState(() {
      if (fromSkip) {
        _loadingSkip = true;
      } else {
        _loadingAction = true;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (mounted) context.go(AppRoutes.login);
  }

  void _setActiveSlide(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const double heroHeight = 470.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                // 1. Hero Culinary Visual Section (470px height)
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Full-bleed swipeable photography scaled 1.05x
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemBuilder: (context, index) {
                            return Transform.scale(
                              scale: 1.05,
                              child: Image.asset(
                                _slides[index].imageAsset,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            );
                          },
                        ),

                        // Subtle Top Scrim (h-28 = 112px: black/40 -> black/10 -> transparent)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: 112,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha(102),
                                    Colors.black.withAlpha(26),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Top-left Brand Accent Chip
                        Positioned(
                          top: safeTop + 20,
                          left: 20,
                          child: IgnorePointer(
                            child: _FrostedHeroChip(
                              leading: const Icon(
                                Icons.local_fire_department,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              label: slide.leftChip.toUpperCase(),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Top-right Live Freshness Micro-badge
                        Positioned(
                          top: safeTop + 20,
                          right: 20,
                          child: IgnorePointer(
                            child: _FrostedHeroChip(
                              leading: const _PulsingDot(
                                color: AppColors.primary,
                                size: 8,
                              ),
                              label: slide.rightChip,
                              letterSpacing: 0.24,
                            ),
                          ),
                        ),

                        // Seamless Gradient Melt into #FFF8F1 (h-44 = 176px)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 176,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.surface,
                                    AppColors.surface.withAlpha(217),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.48, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Content & Interaction Section (overlaps hero bottom by -mt-10 = -40px -> top: 430px)
                Padding(
                  padding: EdgeInsets.only(
                    top: heroHeight - 40,
                    left: 20, // px-margin = 1.25rem
                    right: 20,
                    bottom: safeBottom + 32, // pb-8
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ambient Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, // px-2.5
                          vertical: 4, // py-1
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed.withAlpha(128),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: AppColors.onSecondaryFixed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              slide.ambientBadge.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                height: 14 / 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppColors.onSecondaryFixed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12), // mb-3

                      // Main Headline (headline-lg: 28px, w700, 34px lineHeight, -0.02em)
                      Text(
                        slide.headline,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 34 / 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.56,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10), // mt-2.5

                      // Descriptive Subtext (body-lg: 16px, w400, 24px lineHeight, max-w-[320px])
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          slide.subtext,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 24 / 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32), // mt-8

                      // Interactive Page Indicator Carousel Dots
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final isActive = i == _currentPage;
                          return Padding(
                            padding: EdgeInsets.only(
                                right: i < _slides.length - 1 ? 8 : 0),
                            child: GestureDetector(
                              onTap: () => _setActiveSlide(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isActive ? 28 : 8, // w-7 vs w-2
                                height: 8, // h-2
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primaryContainer
                                      : AppColors.tertiaryFixedDim,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(15),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40), // mt-10

                      // Action Group Stack
                      Column(
                        children: [
                          // Secondary Skip Action
                          GestureDetector(
                            onTap: () => _completeOnboarding(fromSkip: true),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 16,
                              ),
                              child: Opacity(
                                opacity: _loadingSkip ? 0.5 : 1.0,
                                child: Text(
                                  _loadingSkip ? 'Loading feed...' : 'Skip',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 18 / 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.14,
                                    color: AppColors.tertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12), // gap-3

                          // Primary Custom Pill CTA ("Get Started")
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _loadingAction
                                  ? null
                                  : () => _completeOnboarding(fromSkip: false),
                              borderRadius: BorderRadius.circular(9999),
                              child: Container(
                                width: double.infinity,
                                height: 56, // h-14
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer
                                          .withAlpha(97), // 0.38
                                      blurRadius: 30,
                                      spreadRadius: -6,
                                      offset: const Offset(0, 14),
                                    ),
                                    BoxShadow(
                                      color: AppColors.onTertiaryFixed
                                          .withAlpha(15), // 0.06
                                      blurRadius: 12,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _loadingAction
                                      ? const [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Opening Menu...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 18 / 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.35,
                                              color:
                                                  AppColors.onPrimaryContainer,
                                            ),
                                          ),
                                        ]
                                      : const [
                                          Text(
                                            'Get Started',
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 18 / 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.35,
                                              color:
                                                  AppColors.onPrimaryContainer,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward,
                                            size: 20,
                                            color: AppColors.onPrimaryContainer,
                                          ),
                                        ],
                                ),
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
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String imageAsset;
  final String leftChip;
  final String rightChip;
  final String ambientBadge;
  final String headline;
  final String subtext;

  const _OnboardingSlide({
    required this.imageAsset,
    required this.leftChip,
    required this.rightChip,
    required this.ambientBadge,
    required this.headline,
    required this.subtext,
  });
}

class _FrostedHeroChip extends StatelessWidget {
  final Widget leading;
  final String label;
  final double letterSpacing;

  const _FrostedHeroChip({
    required this.leading,
    required this.label,
    required this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withAlpha(204),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: letterSpacing,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, this.size = 8});

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
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
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
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
