import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/models/order.dart';
import '../controllers/order_providers.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _orderExpanded = true;
  bool _satelliteTint = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatShortTime(DateTime dt) {
    final local = dt.toLocal();
    final h12 = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h12:$m $period';
  }

  String _fallbackAssetForItem(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pizza')) return 'assets/images/pizza.png';
    if (lower.contains('burger')) return 'assets/images/burger.png';
    return 'assets/images/biryani.png';
  }

  void _showInvoiceModal(
    OrderModel? order,
    String shortOrderId,
    List<Map<String, dynamic>> items,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text(
                'Order Invoice • #SV-$shortOrderId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isNotEmpty)
                ...items.map((item) {
                  final name = (item['name'] ?? 'Dish').toString();
                  final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                  final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$qty× $name',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '\$${(price * qty).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const Divider(height: 20, color: AppColors.surfaceContainerHigh),
              if (order != null) ...[
                _InvoiceLine(
                  'Subtotal',
                  '\$${order.subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 4),
                _InvoiceLine(
                  'Delivery Fee',
                  '\$${order.deliveryFee.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _InvoiceLine(
                  'Total Amount',
                  '\$${order.total.toStringAsFixed(2)}',
                  highlight: true,
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Close Invoice',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpSheet(String shortOrderId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Need Help with Order?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Savora Support is ready to assist you with order #SV-$shortOrderId. You can call your courier Bilal Tariq directly or contact 24/7 kitchen concierge.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connected to Savora Support concierge!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.onSurface,
                ),
              );
            },
            child: const Text('Call Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(orderEventsStreamProvider(widget.orderId));
    final orderAsync = ref.watch(orderStreamProvider(widget.orderId));
    final itemsAsync = ref.watch(orderItemsProvider(widget.orderId));

    final order = orderAsync.valueOrNull;
    final events = eventsAsync.valueOrNull ?? const <OrderEvent>[];
    final items = itemsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    final liveStatus = order?.status ??
        (events.isNotEmpty ? events.last.status : 'confirmed');

    final isPreparing = liveStatus == 'preparing' ||
        liveStatus == 'out_for_delivery' ||
        liveStatus == 'delivered';
    final isOnTheWay =
        liveStatus == 'out_for_delivery' || liveStatus == 'delivered';
    final isDelivered = liveStatus == 'delivered';

    final progressFactor = isDelivered
        ? 1.0
        : isOnTheWay
            ? 0.72
            : isPreparing
                ? 0.45
                : 0.22;

    final statusBadgeText = isDelivered
        ? 'DELIVERED ✅'
        : isOnTheWay
            ? 'ON THE WAY 🛵'
            : isPreparing
                ? 'PREPARING 👨‍🍳'
                : 'CONFIRMED ✅';

    final headlineText = isDelivered
        ? 'Order Delivered!'
        : isOnTheWay
            ? 'Arriving in 18 mins'
            : isPreparing
                ? 'Chef is preparing your meal'
                : 'Order confirmed by kitchen';

    final subtitleText = isDelivered
        ? 'Your meal was dropped off safely. Enjoy every bite!'
        : isOnTheWay
            ? 'Your rider Bilal is en route with your fresh, piping hot food.'
            : isPreparing
                ? 'Fresh ingredients are sizzling in the kitchen right now.'
                : 'Your order is queued and will begin cooking shortly.';

    final riderT = isDelivered
        ? 0.94
        : isOnTheWay
            ? 0.50
            : isPreparing
                ? 0.22
                : 0.08;

    final baseTime = order?.createdAt ?? DateTime.now();
    final placedTimeStr = _formatShortTime(baseTime);
    final kitchenTimeStr =
        _formatShortTime(baseTime.add(const Duration(minutes: 10)));
    final onRouteTimeStr =
        _formatShortTime(baseTime.add(const Duration(minutes: 18)));
    final estArrivalStr =
        _formatShortTime(baseTime.add(const Duration(minutes: 32)));

    final shortOrderId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId.toUpperCase();

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final totalItemCount = items.fold<int>(
      0,
      (sum, e) => sum + ((e['quantity'] as num?)?.toInt() ?? 1),
    );
    final firstItemName = items.isNotEmpty
        ? (items.first['name'] ?? 'Artisan Dish').toString()
        : 'Savora Signature Feast';
    final itemPreviewSummary = items.isEmpty
        ? 'Prepared fresh to order'
        : items.length == 1
            ? firstItemName
            : '$firstItemName +${items.length - 1}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Canvas + Floating Overlap Sheet
          SingleChildScrollView(
            padding: EdgeInsets.only(top: safeTop + 64),
            child: Stack(
              children: [
                // 1. Stylized Live Map Header (320px / h-80)
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      const h = 320.0;
                      final riderPos = _bezierPointForT(riderT, w, h);

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MapCanvasPainter(
                                satelliteTint: _satelliteTint,
                              ),
                            ),
                          ),

                          // Live Animated Rider Beacon along Route Curve
                          Positioned(
                            left: riderPos.dx - 26,
                            top: riderPos.dy - 26,
                            width: 52,
                            height: 52,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, _) {
                                final p = _pulseController.value;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 0.7 + (p * 0.9),
                                      child: Opacity(
                                        opacity:
                                            (0.45 * (1.0 - p)).clamp(0.0, 0.45),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.40),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.two_wheeler,
                                        size: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Origin Location Label Tag
                          Positioned(
                            top: 44,
                            left: 20,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest
                                        .withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 4,
                                        backgroundColor: AppColors.secondary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Spice Craft, Clifton',
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
                            ),
                          ),

                          // Floating Est. Arrival Pill Tag
                          Positioned(
                            top: 16,
                            right: 20,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest
                                        .withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.10),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (_, _) {
                                            final p = _pulseController.value;
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Transform.scale(
                                                  scale: 0.8 + p * 1.1,
                                                  child: Opacity(
                                                    opacity: (1 - p)
                                                        .clamp(0.0, 0.75),
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: AppColors.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 9,
                                                  height: 9,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Est. Arrival',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            isDelivered
                                                ? 'Delivered'
                                                : '$estArrivalStr (15–20m)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface,
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

                          // Map Viewport Controls (Recenter + Layers)
                          Positioned(
                            bottom: 38,
                            right: 20,
                            child: Column(
                              children: [
                                _MapViewportButton(
                                  icon: Icons.near_me,
                                  onTap: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Map recentered on active courier route.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                _MapViewportButton(
                                  icon: Icons.layers,
                                  onTap: () {
                                    setState(
                                      () => _satelliteTint = !_satelliteTint,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 2. Primary Floating Tracking Sheet (-24px overlap)
                Padding(
                  padding: const EdgeInsets.only(top: 296),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + 40),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Visual Sheet Grab Notch
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),

                        // Status Pill Badge & Monospace Order ID
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed
                                    .withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FadeTransition(
                                    opacity: Tween<double>(
                                      begin: 0.45,
                                      end: 1.0,
                                    ).animate(_pulseController),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusBadgeText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppColors.onSecondaryFixed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Order #SV-$shortOrderId',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Headline & Subtext
                        Text(
                          headlineText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: AppColors.onSurface,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. 4-Stage Milestone Tracking Timeline
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 500),
                                    widthFactor: progressFactor,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MilestoneStep(
                                      title: 'Placed',
                                      time: placedTimeStr,
                                      isPassed: true,
                                      isActive: !isPreparing,
                                      pulseController: _pulseController,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MilestoneStep(
                                      title: 'Kitchen',
                                      time: kitchenTimeStr,
                                      isPassed: isOnTheWay,
                                      isActive: isPreparing && !isOnTheWay,
                                      pulseController: _pulseController,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MilestoneStep(
                                      title: 'On Route',
                                      time: onRouteTimeStr,
                                      isPassed: isDelivered,
                                      isActive: isOnTheWay && !isDelivered,
                                      pulseController: _pulseController,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MilestoneStep(
                                      title: 'Delivered',
                                      time: isDelivered
                                          ? 'Done'
                                          : 'Est. $estArrivalStr',
                                      isPassed: isDelivered,
                                      isActive: false,
                                      isFinalHome: true,
                                      pulseController: _pulseController,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 4. Delivery Hero / Courier Profile Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryFixed,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining,
                                      size: 26,
                                      color: AppColors.onSecondaryFixed,
                                    ),
                                  ),
                                  Positioned(
                                    right: -3,
                                    bottom: -3,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryFixed,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: AppColors.onSecondaryFixed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Bilal Tariq',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.18,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '★ 4.9',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Honda CD70 • KHI-9042',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '1,240+ deliveries',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _CourierActionButton(
                                icon: Icons.call,
                                iconColor: AppColors.primary,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Dialing courier Bilal Tariq...',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _CourierActionButton(
                                icon: Icons.chat_bubble_outline,
                                iconColor: AppColors.onSurface,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Opening chat with courier Bilal...',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 5. Expandable Order Items Summary Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(
                                  () => _orderExpanded = !_orderExpanded,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.asset(
                                              _fallbackAssetForItem(
                                                firstItemName,
                                              ),
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Flexible(
                                                      child: Text(
                                                        'Spice Craft Karachi',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 7,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .secondaryFixed
                                                            .withValues(
                                                          alpha: 0.50,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: Text(
                                                        totalItemCount > 0
                                                            ? '$totalItemCount ${totalItemCount == 1 ? 'Item' : 'Items'}'
                                                            : 'Order',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .onSecondaryFixed,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  itemPreviewSummary,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _orderExpanded ? 0.5 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.expand_more,
                                        size: 20,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_orderExpanded) ...[
                                const SizedBox(height: 12),
                                if (items.isEmpty)
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Prepared fresh with artisanal spices',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                else
                                  ...items.map((item) {
                                    final name =
                                        (item['name'] ?? 'Dish').toString();
                                    final qty =
                                        (item['quantity'] as num?)?.toInt() ??
                                            1;
                                    final price =
                                        (item['price'] as num?)?.toDouble() ??
                                            0.0;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$qty× $name',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '\$${(price * qty).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            order?.paymentMethod == 'card'
                                                ? Icons.credit_card
                                                : Icons.payments_outlined,
                                            size: 16,
                                            color: AppColors.secondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            order?.paymentMethod == 'card'
                                                ? 'Paid via Stripe'
                                                : 'Cash on Delivery',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Total: \$${(order?.total ?? 0.0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
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

                        // 6. Drop-off Destination Mini-Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow
                                .withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryFixed
                                      .withValues(alpha: 0.50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: AppColors.onSecondaryFixed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Drop-off Destination',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      order?.deliveryAddress ??
                                          'Apartment 402, Ocean Heights, Clifton',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Live Order Completion Actions (preserved cleanly)
                        if (!isDelivered && liveStatus != 'cancelled') ...[
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.outlineVariant,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.fast_forward_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Next Stage',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () => advanceOrderStage(
                                      context: context,
                                      ref: ref,
                                      orderId: widget.orderId,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Confirm Order Delivered',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () => confirmOrderDelivery(
                                      context: context,
                                      ref: ref,
                                      orderId: widget.orderId,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        // 7. Action Group: Share Tracking & Support / Invoice
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Live tracking link copied to clipboard!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.onSurface,
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.ios_share,
                                    size: 18,
                                    color: AppColors.onPrimary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Share Live Tracking Link',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _showHelpSheet(shortOrderId),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Need Help with Order?',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: AppColors.surfaceVariant,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showInvoiceModal(
                                order,
                                shortOrderId,
                                items,
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'View Invoice',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed Frosted mobile_stack Top Header Bar (h-16)
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
                            'Order Tracking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.18,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
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
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Calling Savora Support hotline...',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.call,
                                  size: 24,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tracking link copied to clipboard!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.share_outlined,
                                  size: 24,
                                  color: AppColors.onSurface,
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
        ],
      ),
    );
  }

  Offset _bezierPointForT(double t, double w, double h) {
    final p0 = Offset(w * 0.16, h * 0.256);
    final p1 = Offset(w * 0.34, h * 0.42);
    final p2 = Offset(w * 0.65, h * 0.56);
    final p3 = Offset(w * 0.80, h * 0.738);
    final mt = 1.0 - t;
    final dx = mt * mt * mt * p0.dx +
        3 * mt * mt * t * p1.dx +
        3 * mt * t * t * p2.dx +
        t * t * t * p3.dx;
    final dy = mt * mt * mt * p0.dy +
        3 * mt * mt * t * p1.dy +
        3 * mt * t * t * p2.dy +
        t * t * t * p3.dy;
    return Offset(dx, dy);
  }
}

class _MapViewportButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapViewportButton({required this.icon, required this.onTap});

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
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
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

class _MilestoneStep extends StatelessWidget {
  final String title;
  final String time;
  final bool isPassed;
  final bool isActive;
  final bool isFinalHome;
  final AnimationController pulseController;

  const _MilestoneStep({
    required this.title,
    required this.time,
    required this.isPassed,
    required this.isActive,
    this.isFinalHome = false,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final dimmed = !isPassed && !isActive;

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Column(
        children: [
          if (isPassed)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            )
          else if (isActive)
            SizedBox(
              width: 24,
              height: 24,
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (_, _) {
                  final p = pulseController.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Transform.scale(
                        scale: 0.75 + p * 0.9,
                        child: Opacity(
                          opacity: (1 - p).clamp(0.0, 0.60),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFinalHome ? Icons.home : Icons.circle,
                size: isFinalHome ? 14 : 8,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primary : AppColors.onSurface,
            ),
          ),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourierActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CourierActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InvoiceLine(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: highlight ? 15 : 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color:
                highlight ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 17 : 13,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Custom Vector Canvas Painter for order tracking route map
class _MapCanvasPainter extends CustomPainter {
  final bool satelliteTint;

  _MapCanvasPainter({required this.satelliteTint});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color =
          satelliteTint ? const Color(0xFFEDE6DD) : AppColors.surfaceContainer;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Coastline water curves
    final water1 = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.35);
    final path1 = Path()
      ..moveTo(-20, size.height * 0.87)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.69,
        size.width * 0.45,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.95,
        size.width + 20,
        size.height * 0.75,
      )
      ..lineTo(size.width + 20, size.height)
      ..lineTo(-20, size.height)
      ..close();
    canvas.drawPath(path1, water1);

    final water2 = Paint()
      ..color = AppColors.secondaryContainer.withValues(alpha: 0.25);
    final path2 = Path()
      ..moveTo(-20, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.76,
        size.width * 0.50,
        size.height * 0.89,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.98,
        size.width + 20,
        size.height * 0.81,
      )
      ..lineTo(size.width + 20, size.height)
      ..lineTo(-20, size.height)
      ..close();
    canvas.drawPath(path2, water2);

    // City Blocks & Roads Grid
    final roadDark = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..strokeWidth = 5;
    final roadLight = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..strokeWidth = 5;

    canvas.drawLine(
      Offset(size.width * 0.08, 0),
      Offset(size.width * 0.08, size.height),
      roadDark,
    );
    canvas.drawLine(
      Offset(size.width * 0.30, 0),
      Offset(size.width * 0.30, size.height),
      roadDark,
    );
    canvas.drawLine(
      Offset(size.width * 0.525, 0),
      Offset(size.width * 0.525, size.height),
      roadDark,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, 0),
      Offset(size.width * 0.80, size.height),
      roadLight,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.19),
      Offset(size.width, size.height * 0.19),
      roadLight,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.41),
      Offset(size.width, size.height * 0.41),
      roadDark,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.66),
      Offset(size.width, size.height * 0.66),
      roadLight,
    );

    // Primary Arterial Avenues
    final arterialPaint = Paint()
      ..color = AppColors.surfaceDim
      ..strokeWidth = 11
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ave1 = Path()
      ..moveTo(-20, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.37,
        size.height * 0.44,
        size.width * 0.65,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.25,
        size.width + 20,
        size.height * 0.16,
      );
    canvas.drawPath(ave1, arterialPaint);

    // Route Trace (Origin to Destination)
    final p0 = Offset(size.width * 0.16, size.height * 0.256);
    final p1 = Offset(size.width * 0.34, size.height * 0.42);
    final p2 = Offset(size.width * 0.65, size.height * 0.56);
    final p3 = Offset(size.width * 0.80, size.height * 0.738);

    final routePath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    final routeUnderlay = Paint()
      ..color = AppColors.secondaryContainer.withValues(alpha: 0.60)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeUnderlay);

    // Dashed Active Route Stroke (#A83300)
    final dashedPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in routePath.computeMetrics()) {
      double distance = 0;
      const dashLen = 7.0;
      const gapLen = 5.0;
      while (distance < metric.length) {
        final next = (distance + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), dashedPaint);
        distance += dashLen + gapLen;
      }
    }

    // Origin Node (White halo -> Dark charcoal circle -> White core)
    canvas.drawCircle(p0, 14, Paint()..color = Colors.white);
    canvas.drawCircle(p0, 10, Paint()..color = AppColors.inverseSurface);
    canvas.drawCircle(p0, 4, Paint()..color = Colors.white);

    // Destination Teardrop Pin Marker
    final pinPath = Path()
      ..moveTo(p3.dx, p3.dy)
      ..lineTo(p3.dx - 7, p3.dy - 14)
      ..cubicTo(
        p3.dx - 11,
        p3.dy - 23,
        p3.dx - 8,
        p3.dy - 31,
        p3.dx,
        p3.dy - 31,
      )
      ..cubicTo(
        p3.dx + 8,
        p3.dy - 31,
        p3.dx + 11,
        p3.dy - 23,
        p3.dx + 7,
        p3.dy - 14,
      )
      ..close();
    canvas.drawShadow(pinPath, Colors.black.withValues(alpha: 0.25), 4, false);
    canvas.drawPath(pinPath, Paint()..color = AppColors.inverseSurface);
    canvas.drawCircle(
      Offset(p3.dx, p3.dy - 20),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) =>
      oldDelegate.satelliteTint != satelliteTint;
}
