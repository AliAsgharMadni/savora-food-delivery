import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/savora_empty_states.dart';
import '../../../../core/widgets/savora_floating_nav.dart';
import '../../../../core/widgets/savora_tab_header.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../data/models/order.dart';
import '../controllers/order_providers.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _activeFilter = 'all';
  String _sortOrder = 'newest';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  final Map<String, int> _localRatings = {};

  static const _filters = [
    {'key': 'all', 'label': 'All Orders'},
    {'key': 'ongoing', 'label': 'Ongoing'},
    {'key': 'completed', 'label': 'Completed'},
    {'key': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderModel> _applyFilter(List<OrderModel> orders) {
    Iterable<OrderModel> filtered = orders;

    switch (_activeFilter) {
      case 'ongoing':
        filtered = filtered.where((o) =>
            o.status == 'pending' ||
            o.status == 'confirmed' ||
            o.status == 'preparing' ||
            o.status == 'out_for_delivery');
        break;
      case 'completed':
        filtered = filtered.where((o) => o.status == 'delivered');
        break;
      case 'cancelled':
        filtered = filtered.where((o) => o.status == 'cancelled');
        break;
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((o) =>
          o.id.toLowerCase().contains(query) ||
          o.deliveryAddress.toLowerCase().contains(query) ||
          o.status.toLowerCase().contains(query));
    }

    final list = filtered.toList();
    if (_sortOrder == 'oldest') {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortOrder == 'highest') {
      list.sort((a, b) => b.total.compareTo(a.total));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  int _countFilter(List<OrderModel> orders, String key) {
    return orders.where((o) {
      if (key == 'all') return true;
      if (key == 'ongoing') {
        return o.status == 'pending' ||
            o.status == 'confirmed' ||
            o.status == 'preparing' ||
            o.status == 'out_for_delivery';
      }
      if (key == 'completed') return o.status == 'delivered';
      if (key == 'cancelled') return o.status == 'cancelled';
      return true;
    }).length;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort Orders By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.primary),
              title: const Text('Newest First'),
              trailing: _sortOrder == 'newest'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _sortOrder = 'newest');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: const Text('Oldest First'),
              trailing: _sortOrder == 'oldest'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _sortOrder = 'oldest');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.attach_money, color: AppColors.primary),
              title: const Text('Highest Amount'),
              trailing: _sortOrder == 'highest'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _sortOrder = 'highest');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRateSheet(OrderModel order) {
    int stars = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Rate Your Meal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'How did Spice Craft & Savora deliver today?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < stars;
                  return IconButton(
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      size: 36,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setModalState(() => stars = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _localRatings[order.id] = stars);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thanks for your $stars★ rating!'),
                        backgroundColor: AppColors.onSurface,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Submit Rating',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider);

    final profileName = userProfile?.fullName?.trim() ?? '';
    final rawName =
        profileName.isNotEmpty ? profileName : (currentUser?.email ?? 'S');
    final userInitial = rawName.isNotEmpty ? rawName[0].toUpperCase() : 'S';

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Orders Stream
          Positioned.fill(
            child: ordersAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.only(top: safeTop + 64),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Padding(
                padding: EdgeInsets.only(top: safeTop + 64),
                child: _buildError(err.toString()),
              ),
              data: (orders) {
                final filtered = _applyFilter(orders);
                return RefreshIndicator(
                  color: AppColors.primary,
                  edgeOffset: safeTop + 64,
                  onRefresh: () async => ref.invalidate(userOrdersProvider),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(height: safeTop + 64),
                      ),

                      // Screen Header Action Row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order History',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.56,
                                            height: 1.2,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Track, reorder, or review past feasts',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _CircleActionBtn(
                                        icon: _showSearch
                                            ? Icons.close
                                            : Icons.search,
                                        onTap: () => setState(() {
                                          _showSearch = !_showSearch;
                                          if (!_showSearch) {
                                            _searchCtrl.clear();
                                          }
                                        }),
                                      ),
                                      const SizedBox(width: 6),
                                      _CircleActionBtn(
                                        icon: Icons.tune,
                                        onTap: _showFilterSheet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (_showSearch) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _searchCtrl,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search by order # or address...',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceContainerLowest,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(999),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Filter Chips Horizontal Scroll
                      SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: _filters.map((f) {
                              final key = f['key']!;
                              final count = _countFilter(orders, key);
                              final isActive = _activeFilter == key;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _activeFilter = key),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.inverseSurface
                                          : AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (key == 'ongoing') ...[
                                          _PulsingDot(
                                            color: isActive
                                                ? AppColors.secondaryContainer
                                                : AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          '${f['label']} ($count)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isActive
                                                ? AppColors.inverseOnSurface
                                                : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Orders Stream List or Empty State
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final order = filtered[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _OrderCard(
                                    order: order,
                                    ratingStars: _localRatings[order.id],
                                    onRateTap: () => _showRateSheet(order),
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),

                        // Friendly End of Feed Archive Card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              4,
                              20,
                              safeBottom + 116,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer
                                          .withValues(alpha: 0.40),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.history_edu,
                                      size: 24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Looking for older receipts?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.18,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 250),
                                    child: const Text(
                                      'Invoices older than 60 days are archived safely in your Savora monthly statements.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.45,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Material(
                                    color: AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(999),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Annual monthly PDF statement prepared!',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor:
                                                AppColors.onSurface,
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          'Download Annual PDF',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Fixed Frosted mobile_tab Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SavoraTabHeader(
              title: 'Order History',
              userInitial: userInitial,
            ),
          ),

          // Detached Floating Charcoal Navigation Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SavoraFloatingNav(
              currentIndex: -1,
              cartCount: cartCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Error loading orders: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => ref.invalidate(userOrdersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: SavoraNoOrdersView(
        onOrderNow: () => context.go(AppRoutes.home),
      ),
    );
  }
}

class _CircleActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 20, color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  final int? ratingStars;
  final VoidCallback onRateTap;

  const _OrderCard({
    required this.order,
    this.ratingStars,
    required this.onRateTap,
  });

  String _assetForDishName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pizza')) return 'assets/images/pizza.png';
    if (lower.contains('burger')) return 'assets/images/burger.png';
    return 'assets/images/biryani.png';
  }

  String _formatDateLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final timeStr = DateFormat('h:mm a').format(local);
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Today, $timeStr';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Yesterday, $timeStr';
    }
    return DateFormat('d MMM, h:mm a').format(local);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOngoing = order.status == 'pending' ||
        order.status == 'confirmed' ||
        order.status == 'preparing' ||
        order.status == 'out_for_delivery';

    final itemsAsync = ref.watch(orderItemsProvider(order.id));
    final items = itemsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    final totalCount = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1),
    );

    final summaryTitle = items.isEmpty
        ? order.deliveryAddress
        : items
            .take(2)
            .map((e) => '${e['quantity'] ?? 1}x ${e['name'] ?? 'Dish'}')
            .join(', ') +
            (items.length > 2 ? ' +${items.length - 2}' : '');

    final thumbAssets = items.isEmpty
        ? ['assets/images/biryani.png']
        : items
            .take(2)
            .map((e) => _assetForDishName((e['name'] ?? '').toString()))
            .toList();

    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    final badge = _statusBadge(order.status);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.orderDetail, extra: order),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2602B)
                  .withValues(alpha: isOngoing ? 0.12 : 0.06),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF1E1B19)
                  .withValues(alpha: isOngoing ? 0.04 : 0.03),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Order Gradient Accent Stripe (h-1.5 / 6px)
              if (isOngoing)
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondaryContainer],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Meta & Status Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER #SV-$shortId',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.18,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                _formatDateLabel(order.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: badge.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                badge.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: badge.fg,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badge.emoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Live Delivery Micro Tracker for Ongoing Orders
                    if (isOngoing) ...[
                      const SizedBox(height: 12),
                      _LiveTracker(status: order.status),
                    ],

                    // Overlapping Dish Thumbnails & Summary Row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 48,
                            width: _thumbStackWidth(
                              thumbAssets.length,
                              items.length > 2,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (int idx = 0;
                                    idx < thumbAssets.length;
                                    idx++)
                                  Positioned(
                                    left: idx * 30.0,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          thumbAssets[idx],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (items.length > 2)
                                  Positioned(
                                    left: thumbAssets.length * 30.0,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.10),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+${items.length - 2}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summaryTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: totalCount > 0
                                            ? '$totalCount ${totalCount == 1 ? 'item' : 'items'} · '
                                            : 'Order total · ',
                                      ),
                                      TextSpan(
                                        text:
                                            '\$${order.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isOngoing
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rated Feedback Badge (if rated)
                    if (!isOngoing && ratingStars != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your review',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < ratingStars!
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action Pill Buttons (48px / h-12 height)
                    if (isOngoing)
                      Row(
                        children: [
                          Expanded(
                            child: _HistoryPillButton(
                              height: 48,
                              bgColor: AppColors.primary,
                              fgColor: AppColors.onPrimary,
                              icon: Icons.near_me,
                              label: 'Track Order',
                              shadowColor: AppColors.primary,
                              onTap: () => context.push(
                                AppRoutes.orderTracking,
                                extra: order.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _HistoryPillButton(
                            height: 48,
                            horizontalPadding: 20,
                            bgColor: AppColors.surfaceContainer,
                            fgColor: AppColors.onSurface,
                            label: 'Details',
                            onTap: () => context.push(
                              AppRoutes.orderDetail,
                              extra: order,
                            ),
                          ),
                        ],
                      )
                    else if (order.status == 'delivered' && ratingStars == null)
                      Row(
                        children: [
                          Expanded(
                            child: _HistoryPillButton(
                              height: 48,
                              bgColor: AppColors.inverseSurface,
                              fgColor: AppColors.inverseOnSurface,
                              icon: Icons.replay,
                              label: 'Reorder',
                              onTap: () => reorderPastOrder(
                                context: context,
                                ref: ref,
                                orderId: order.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HistoryPillButton(
                              height: 48,
                              bgColor: AppColors.secondaryContainer
                                  .withValues(alpha: 0.40),
                              fgColor: AppColors.onSecondaryContainer,
                              icon: Icons.star,
                              iconColor: AppColors.primary,
                              label: 'Rate Food',
                              onTap: onRateTap,
                            ),
                          ),
                        ],
                      )
                    else
                      _HistoryPillButton(
                        height: 48,
                        bgColor: AppColors.surfaceContainer,
                        fgColor: AppColors.onSurface,
                        icon: Icons.replay,
                        label: 'Reorder Dish',
                        onTap: () => reorderPastOrder(
                          context: context,
                          ref: ref,
                          orderId: order.id,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _thumbStackWidth(int count, bool hasOverflow) {
    final slots = count + (hasOverflow ? 1 : 0);
    if (slots <= 1) return 48;
    return 48 + ((slots - 1) * 30.0);
  }

  ({String label, String emoji, Color bg, Color fg}) _statusBadge(
    String status,
  ) {
    switch (status) {
      case 'pending':
        return (
          label: 'Pending',
          emoji: '⏳',
          bg: AppColors.surfaceContainerHigh,
          fg: AppColors.onSurfaceVariant,
        );
      case 'confirmed':
        return (
          label: 'Confirmed',
          emoji: '✅',
          bg: AppColors.secondaryFixed,
          fg: AppColors.onSecondaryContainer,
        );
      case 'preparing':
        return (
          label: 'Preparing',
          emoji: '👨‍🍳',
          bg: const Color(0xFFFFF3E0),
          fg: const Color(0xFFE65100),
        );
      case 'out_for_delivery':
        return (
          label: 'On the way',
          emoji: '🛵',
          bg: AppColors.secondaryContainer,
          fg: AppColors.onSecondaryContainer,
        );
      case 'delivered':
        return (
          label: 'Delivered',
          emoji: '✅',
          bg: AppColors.surfaceContainerHigh,
          fg: AppColors.onSurface,
        );
      case 'cancelled':
        return (
          label: 'Cancelled',
          emoji: '❌',
          bg: AppColors.errorContainer,
          fg: AppColors.onErrorContainer,
        );
      default:
        return (
          label: status,
          emoji: '📦',
          bg: AppColors.surfaceContainerHigh,
          fg: AppColors.onSurface,
        );
    }
  }
}

class _HistoryPillButton extends StatelessWidget {
  final double height;
  final double horizontalPadding;
  final Color bgColor;
  final Color fgColor;
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final Color? shadowColor;
  final VoidCallback onTap;

  const _HistoryPillButton({
    required this.height,
    this.horizontalPadding = 16,
    required this.bgColor,
    required this.fgColor,
    this.icon,
    this.iconColor,
    required this.label,
    this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor!.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: iconColor ?? fgColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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

class _LiveTracker extends StatelessWidget {
  final String status;

  const _LiveTracker({required this.status});

  @override
  Widget build(BuildContext context) {
    final progress = status == 'pending'
        ? 0.15
        : status == 'confirmed'
            ? 0.35
            : status == 'preparing'
                ? 0.65
                : 0.78;
    final label = status == 'pending'
        ? 'Awaiting confirmation'
        : status == 'confirmed'
            ? 'Kitchen confirmed'
            : status == 'preparing'
                ? 'Chef is preparing'
                : 'Est. Arrival: 14 mins';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Text(
                'Live route active',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
