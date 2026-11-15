import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../routing/route_names.dart';

/// Shared frosted 64px top bar matching Savora mobile tab header.
class SavoraTabHeader extends StatelessWidget {
  final String title;
  final String? userInitial;
  final VoidCallback? onNotificationTap;
  final bool hasNotificationBadge;

  const SavoraTabHeader({
    super.key,
    required this.title,
    this.userInitial,
    this.onNotificationTap,
    this.hasNotificationBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(top: safeTop),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(204), // bg-surface/80
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
                  // Brandmark + Savora
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: AppColors.onPrimary,
                          size: 17,
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

                  // Centered Page Title
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Right Actions: Notifications + Avatar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onNotificationTap ??
                            () => context.push(AppRoutes.orderHistory),
                        borderRadius: BorderRadius.circular(9999),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 24,
                                color: AppColors.onSurface,
                              ),
                              if (hasNotificationBadge)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => context.push(AppRoutes.profile),
                        borderRadius: BorderRadius.circular(9999),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (userInitial?.isNotEmpty == true)
                                      ? userInitial![0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSecondaryFixedVariant,
                                  ),
                                ),
                              ),
                            ),
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

