import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared illustrated Empty Cart component matching empty_states/code.html (State A).
class SavoraEmptyCartView extends StatelessWidget {
  final VoidCallback onExploreMenu;
  final ValueChanged<String>? onPickSuggestion;

  const SavoraEmptyCartView({
    super.key,
    required this.onExploreMenu,
    this.onPickSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Illustrated Card
        _EmptyHeroCard(
          topRightGlowColor:
              AppColors.secondaryContainer.withValues(alpha: 0.22),
          bottomLeftGlowColor: AppColors.primaryFixed.withValues(alpha: 0.30),
          child: Column(
            children: [
              // 176x176 Illustrated Food Bag Scene
              SizedBox(
                width: 176,
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 144,
                      height: 144,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned(
                            top: 8,
                            right: 16,
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const Positioned(
                            bottom: 24,
                            left: 8,
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 18,
                              color: AppColors.secondaryContainer,
                            ),
                          ),
                          const Positioned(
                            top: 24,
                            left: 20,
                            child: Icon(
                              Icons.cookie_outlined,
                              size: 16,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed
                                  .withValues(alpha: 0.40),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              size: 56,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '0 delicious bites',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your cart feels hungry!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.33,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: const Text(
                  'Explore your neighborhood kitchens and fill your cart with smoky biryani, burgers, and artisanal pizzas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _FullPillCta(
                color: AppColors.primary,
                textColor: AppColors.onPrimary,
                label: 'Explore Food Menu',
                trailingIcon: Icons.arrow_forward,
                onTap: onExploreMenu,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Micro-Recommendation Carousel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular to kickstart your cart',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'Savora Picks',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickPickPill(
                      icon: Icons.local_fire_department,
                      iconColor: AppColors.primary,
                      label: 'Truffle Smash Burger',
                      onTap: () => (onPickSuggestion != null)
                          ? onPickSuggestion!('Burger')
                          : onExploreMenu(),
                    ),
                    const SizedBox(width: 8),
                    _QuickPickPill(
                      icon: Icons.ramen_dining,
                      iconColor: AppColors.secondary,
                      label: 'Smoky Chicken Biryani',
                      onTap: () => (onPickSuggestion != null)
                          ? onPickSuggestion!('Biryani')
                          : onExploreMenu(),
                    ),
                    const SizedBox(width: 8),
                    _QuickPickPill(
                      icon: Icons.local_pizza,
                      iconColor: AppColors.primary,
                      label: 'Spicy Burrata Pizza',
                      onTap: () => (onPickSuggestion != null)
                          ? onPickSuggestion!('Pizza')
                          : onExploreMenu(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared illustrated No Orders component matching empty_states/code.html (State B).
class SavoraNoOrdersView extends StatelessWidget {
  final VoidCallback onOrderNow;

  const SavoraNoOrdersView({
    super.key,
    required this.onOrderNow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmptyHeroCard(
          topLeftGlowColor: AppColors.secondaryFixed.withValues(alpha: 0.45),
          child: Column(
            children: [
              SizedBox(
                width: 176,
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 144,
                      height: 144,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned(
                            top: 12,
                            left: 16,
                            child: Icon(
                              Icons.moped,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const Positioned(
                            bottom: 16,
                            right: 12,
                            child: Icon(
                              Icons.schedule,
                              size: 18,
                              color: AppColors.outline,
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  size: 52,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 18,
                                    color: AppColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.outline,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'No Active Trackers',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No orders placed yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.33,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: const Text(
                  'Once you order your favorite meal, you will be able to track live delivery and reorder anytime right here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _FullPillCta(
                color: AppColors.primary,
                textColor: AppColors.onPrimary,
                leadingIcon: Icons.lunch_dining,
                label: 'Order Now',
                onTap: onOrderNow,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2-Column Benefit Cards
        const Row(
          children: [
            Expanded(
              child: _BenefitMiniCard(
                icon: Icons.pin_drop,
                iconBg: AppColors.secondaryFixed,
                iconFg: AppColors.onSecondaryFixed,
                title: 'Live GPS Tracking',
                subtitle: 'Real-time driver route',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _BenefitMiniCard(
                icon: Icons.autorenew,
                iconBg: AppColors.primaryFixed,
                iconFg: AppColors.onPrimaryFixed,
                title: '1-Tap Reorder',
                subtitle: 'Your favorites in seconds',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared illustrated No Search Results component matching empty_states/code.html (State C).
class SavoraNoSearchView extends StatelessWidget {
  final String query;
  final VoidCallback onBrowseAll;
  final ValueChanged<String> onSelectSuggestion;

  const SavoraNoSearchView({
    super.key,
    required this.query,
    required this.onBrowseAll,
    required this.onSelectSuggestion,
  });

  static const _suggestions = [
    'Biryani',
    'Burger',
    'Pizza',
    'Desserts',
  ];

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim();
    final queryLabel = trimmedQuery.isEmpty
        ? 'No matching dish'
        : 'Query: "$trimmedQuery"';

    return _EmptyHeroCard(
      topRightGlowColor: AppColors.primaryFixed.withValues(alpha: 0.25),
      child: Column(
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 144,
                  height: 144,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.dinner_dining,
                            size: 40,
                            color: AppColors.outlineVariant,
                          ),
                        ),
                        Positioned(
                          top: -10,
                          child: Icon(
                            Icons.air,
                            size: 20,
                            color: AppColors.primary.withValues(alpha: 0.70),
                          ),
                        ),
                        Positioned(
                          bottom: -6,
                          right: -4,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.search_off,
                              size: 20,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            queryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'We couldn’t find that dish',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.33,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: const Text(
              'Try searching for biryani, smash burgers, Neapolitan pizza, or browse popular categories.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Popular Suggestion Tags
          const Text(
            'TRY SEARCHING FOR:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((tag) {
              return Material(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelectSuggestion(tag),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _FullPillCta(
            color: AppColors.inverseSurface,
            textColor: AppColors.inverseOnSurface,
            leadingIcon: Icons.category,
            label: 'Browse All Cuisines',
            onTap: onBrowseAll,
          ),
        ],
      ),
    );
  }
}

class _EmptyHeroCard extends StatelessWidget {
  final Color? topRightGlowColor;
  final Color? topLeftGlowColor;
  final Color? bottomLeftGlowColor;
  final Widget child;

  const _EmptyHeroCard({
    this.topRightGlowColor,
    this.topLeftGlowColor,
    this.bottomLeftGlowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14F2602B),
            blurRadius: 24,
            spreadRadius: -4,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0A1E1B19),
            blurRadius: 12,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (topRightGlowColor != null)
              Positioned(
                top: -48,
                right: -48,
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: topRightGlowColor,
                  ),
                ),
              ),
            if (topLeftGlowColor != null)
              Positioned(
                top: -40,
                left: -40,
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: topLeftGlowColor,
                  ),
                ),
              ),
            if (bottomLeftGlowColor != null)
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bottomLeftGlowColor,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullPillCta extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final String label;
  final VoidCallback onTap;

  const _FullPillCta({
    required this.color,
    required this.textColor,
    this.leadingIcon,
    this.trailingIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 20, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 20, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPickPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickPickPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;

  const _BenefitMiniCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

