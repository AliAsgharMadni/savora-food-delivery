import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/models/order.dart';
import '../controllers/order_providers.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const PaymentSuccessScreen({super.key, required this.order});

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatEtaTime(DateTime createdAt) {
    final eta = createdAt.toLocal().add(const Duration(minutes: 25));
    final hour12 = eta.hour == 0
        ? 12
        : eta.hour > 12
            ? eta.hour - 12
            : eta.hour;
    final minute = eta.minute.toString().padLeft(2, '0');
    final period = eta.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  IconData _iconForDish(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani') || lower.contains('rice')) {
      return Icons.rice_bowl;
    }
    if (lower.contains('burger')) return Icons.lunch_dining;
    if (lower.contains('pizza')) return Icons.local_pizza;
    if (lower.contains('lime') ||
        lower.contains('drink') ||
        lower.contains('shake')) {
      return Icons.local_bar;
    }
    return Icons.restaurant;
  }

  Color _iconColorForDish(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('biryani') || lower.contains('pizza')) {
      return AppColors.primary;
    }
    if (lower.contains('burger')) return AppColors.secondary;
    return AppColors.tertiary;
  }

  void _showReceiptModal(String shortId) {
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
                'Order Receipt • #SV-$shortId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _ReceiptLine('Subtotal', '\$${widget.order.subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 6),
              _ReceiptLine('Delivery Fee', '\$${widget.order.deliveryFee.toStringAsFixed(2)}'),
              const Divider(height: 20, color: AppColors.surfaceContainerHigh),
              _ReceiptLine(
                'Total Paid',
                '\$${widget.order.total.toStringAsFixed(2)}',
                highlight: true,
              ),
              const SizedBox(height: 20),
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
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt saved to your order archive.'),
                        backgroundColor: AppColors.onSurface,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Done',
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

  void _showHelpDialog(String shortId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Savora Concierge Support',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Need help with order #SV-$shortId? You can monitor live kitchen progress on the tracking screen or contact kitchen support anytime.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
              context.go(AppRoutes.orderTracking, extra: widget.order.id);
            },
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortOrderId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    final itemsAsync = ref.watch(orderItemsProvider(order.id));
    final orderItems = itemsAsync.valueOrNull ?? const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            children: [
              // 1. Celebration Glow, Animated Steam & Visual Cloche Element
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: SizedBox(
                    width: 176,
                    height: 172,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Warm ambient aura
                        Container(
                          width: 172,
                          height: 172,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.secondaryContainer
                                    .withValues(alpha: 0.35),
                                AppColors.secondaryContainer
                                    .withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Outer 144x144 Joy Ring
                        SizedBox(
                          width: 144,
                          height: 144,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Animated Rising Steam above Cloche
                              Positioned(
                                top: -18,
                                child: AnimatedBuilder(
                                  animation: _animController,
                                  builder: (_, _) => CustomPaint(
                                    size: const Size(112, 46),
                                    painter: _SteamPainter(
                                      progress: _animController.value,
                                    ),
                                  ),
                                ),
                              ),

                              // Outer Circle Surface
                              Container(
                                width: 144,
                                height: 144,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  // Inner 96x96 Gradient Cloche Plate
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                        colors: [
                                          AppColors.primaryFixed,
                                          AppColors.surfaceContainerLowest,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x0D1E1B19),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.dinner_dining,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),

                              // Overlapping 44x44 Verified Seal Badge
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.onPrimary,
                                    size: 24,
                                  ),
                                ),
                              ),

                              // Floating Pill Left: Fresh
                              Positioned(
                                top: -2,
                                left: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Fresh',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Floating Pill Right: Chef Prep 🔥
                              Positioned(
                                top: 32,
                                right: -12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Chef Prep 🔥',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSecondary,
                                    ),
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

              // 2. Primary Headline & Subtext
              const SizedBox(height: 8),
              const Text(
                'Order Placed Successfully! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.33,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: 'Your order '),
                      TextSpan(
                        text: '#SV-$shortOrderId',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const TextSpan(text: ' has been confirmed by '),
                      const TextSpan(
                        text: 'Savora Kitchen',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const TextSpan(text: ' and the chef is preparing your meal.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Key Info Card (32px / rounded-lg radius)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ETA Banner Row
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.two_wheeler,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ESTIMATED DELIVERY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _formatEtaTime(order.createdAt),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer
                                  .withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '20–25 mins',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delivery Address Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DELIVERY ADDRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Items Summary Micro-List
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow
                            .withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                orderItems.isEmpty
                                    ? 'Order Summary'
                                    : 'Order Summary (${orderItems.length} ${orderItems.length == 1 ? 'item' : 'items'})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const Text(
                                'Savora Kitchen',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: orderItems.isEmpty
                                  ? [
                                      _ItemMicroPill(
                                        icon: Icons.dinner_dining,
                                        iconColor: AppColors.primary,
                                        label: 'Fresh Artisan Feast',
                                      ),
                                    ]
                                  : orderItems.map((item) {
                                      final name =
                                          (item['name'] ?? 'Dish').toString();
                                      final qty = item['quantity'] ?? 1;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: _ItemMicroPill(
                                          icon: _iconForDish(name),
                                          iconColor: _iconColorForDish(name),
                                          label: '$qty× $name',
                                        ),
                                      );
                                    }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                order.paymentMethod == 'card'
                                    ? Icons.credit_card
                                    : Icons.payments_outlined,
                                size: 15,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  order.paymentMethod == 'card'
                                      ? 'Card ending in ••42'
                                      : 'Cash on Delivery',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Total Paid',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Live Preparation Status Pulse Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (_, _) {
                              final ping = _animController.value;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: 0.8 + (ping * 1.1),
                                    child: Opacity(
                                      opacity: (1.0 - ping).clamp(0.0, 0.75),
                                      child: Container(
                                        width: 12,
                                        height: 12,
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
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Kitchen is crafting your dishes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Live Status',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Stacked Action CTAs
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
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
                    onTap: () => context.go(
                      AppRoutes.orderTracking,
                      extra: order.id,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 20,
                                color: AppColors.onPrimary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Track Order Live',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: AppColors.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.go(AppRoutes.home),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 18,
                          color: AppColors.onSurface,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 6. Confirmation SMS/Email Note & Utility Links
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 15,
                    color: AppColors.outline,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'A confirmation SMS and email have been sent to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showReceiptModal(shortOrderId),
                    child: const Text(
                      'Download Receipt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.outlineVariant,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showHelpDialog(shortOrderId),
                    child: const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SteamPainter extends CustomPainter {
  final double progress;

  _SteamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final specs = [
      (x: size.width * 0.25, h: 28.0, phase: 0.0, stroke: 2.4),
      (x: size.width * 0.50, h: 32.0, phase: 0.35, stroke: 2.8),
      (x: size.width * 0.75, h: 28.0, phase: 0.7, stroke: 2.4),
    ];

    for (final s in specs) {
      final p = (progress + s.phase) % 1.0;
      final opacity = 0.28 + 0.62 * math.sin(p * math.pi);
      final paint = Paint()
        ..color = AppColors.primaryContainer.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.stroke
        ..strokeCap = StrokeCap.round;

      final shift = (p - 0.5) * 4.0;
      final path = Path()
        ..moveTo(s.x, size.height - 6)
        ..cubicTo(
          s.x - 4 + shift,
          size.height - s.h * 0.35,
          s.x + 5 - shift,
          size.height - s.h * 0.7,
          s.x - 1,
          size.height - s.h - (p * 5),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ItemMicroPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _ItemMicroPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
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
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ReceiptLine(this.label, this.value, {this.highlight = false});

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
