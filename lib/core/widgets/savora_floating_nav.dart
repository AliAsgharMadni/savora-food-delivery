import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../routing/route_names.dart';

/// Detached floating charcoal pill dock matching Savora mobile navigation.
class SavoraFloatingNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final VoidCallback? onSearchTap;

  const SavoraFloatingNav({
    super.key,
    required this.currentIndex,
    this.cartCount = 0,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, safeBottom + 16),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface, // #33302b
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onTertiaryFixed.withAlpha(56), // 0.22
                  blurRadius: 40,
                  spreadRadius: -8,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: const Color(0xFFF2602B).withAlpha(36), // 0.14
                  blurRadius: 16,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DockItem(
                  icon: Icons.restaurant,
                  isActive: currentIndex == 0,
                  onTap: () {
                    if (currentIndex != 0) context.go(AppRoutes.home);
                  },
                ),
                _DockItem(
                  icon: Icons.search,
                  isActive: currentIndex == 1,
                  onTap: onSearchTap ?? () => context.go(AppRoutes.home),
                ),
                _DockItem(
                  icon: Icons.shopping_bag_outlined,
                  isActive: currentIndex == 2,
                  badgeCount: cartCount,
                  onTap: () => context.push(AppRoutes.cart),
                ),
                _DockItem(
                  icon: Icons.person_outline,
                  isActive: currentIndex == 3,
                  onTap: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.inverseOnSurface,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

