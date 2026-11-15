import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/food/presentation/controllers/food_providers.dart';
import '../constants/app_colors.dart';
import '../routing/route_names.dart';
import 'savora_empty_states.dart';

/// Standalone Savora Empty States showcase screen.
class EmptyStatesScreen extends ConsumerStatefulWidget {
  const EmptyStatesScreen({super.key});

  @override
  ConsumerState<EmptyStatesScreen> createState() => _EmptyStatesScreenState();
}

class _EmptyStatesScreenState extends ConsumerState<EmptyStatesScreen> {
  String _activeState = 'cart'; // 'cart', 'orders', 'search'

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              safeTop + 72,
              20,
              safeBottom + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segment Switcher
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _SegmentTab(
                        label: 'Empty Cart',
                        isActive: _activeState == 'cart',
                        onTap: () => setState(() => _activeState = 'cart'),
                      ),
                      _SegmentTab(
                        label: 'No Orders',
                        isActive: _activeState == 'orders',
                        onTap: () => setState(() => _activeState = 'orders'),
                      ),
                      _SegmentTab(
                        label: 'No Search',
                        isActive: _activeState == 'search',
                        onTap: () => setState(() => _activeState = 'search'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Active Empty State Viewport
                if (_activeState == 'cart')
                  SavoraEmptyCartView(
                    onExploreMenu: () => context.go(AppRoutes.home),
                    onPickSuggestion: (q) {
                      ref.read(foodSearchQueryProvider.notifier).state = q;
                      context.go(AppRoutes.home);
                    },
                  )
                else if (_activeState == 'orders')
                  SavoraNoOrdersView(
                    onOrderNow: () => context.go(AppRoutes.home),
                  )
                else
                  SavoraNoSearchView(
                    query: 'Dragonfruit Ramen',
                    onBrowseAll: () {
                      ref.read(foodSearchQueryProvider.notifier).state = '';
                      ref.read(selectedCategoryProvider.notifier).state = 'All';
                      context.go(AppRoutes.home);
                    },
                    onSelectSuggestion: (tag) {
                      ref.read(foodSearchQueryProvider.notifier).state = tag;
                      context.go(AppRoutes.home);
                    },
                  ),
                const SizedBox(height: 16),

                // Showcase Context Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer
                                  .withValues(alpha: 0.30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.palette_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Design System Patterns',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Savora Warm Tactile Empty States',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'v2.4',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Frosted mobile_stack Header (h-16)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: safeTop + 64,
                  padding: EdgeInsets.only(top: safeTop, left: 12, right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go(AppRoutes.home),
                                child: const Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Empty States',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.18,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 24,
                          color: AppColors.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (val) =>
                            setState(() => _activeState = val),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'cart',
                            child: Text('Preview Empty Cart'),
                          ),
                          PopupMenuItem(
                            value: 'orders',
                            child: Text('Preview No Orders'),
                          ),
                          PopupMenuItem(
                            value: 'search',
                            child: Text('Preview No Search'),
                          ),
                        ],
                      ),
                    ],
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

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.inverseSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? AppColors.inverseOnSurface
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

