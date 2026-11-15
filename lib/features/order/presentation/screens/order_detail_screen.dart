import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/models/order.dart';
import '../controllers/order_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _assetForDishName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pizza')) return 'assets/images/pizza.png';
    if (lower.contains('burger')) return 'assets/images/burger.png';
    return 'assets/images/biryani.png';
  }

  void _showReceiptDialog(OrderModel order, String shortId) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt #SV-$shortId sent to your registered email.'),
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSupportDialog(String shortId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '24/7 Savora Concierge',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Need assistance with Order #SV-$shortId? Our kitchen & delivery concierge team is ready to help immediately.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting you to Savora Support...'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.onSurface,
                ),
              );
            },
            child: const Text('Connect Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveOrder =
        ref.watch(orderStreamProvider(widget.order.id)).valueOrNull ??
        widget.order;
    final itemsAsync = ref.watch(orderItemsProvider(liveOrder.id));
    final order = liveOrder;

    final isOngoing =
        order.status == 'pending' ||
        order.status == 'confirmed' ||
        order.status == 'preparing' ||
        order.status == 'out_for_delivery';

    final dateStr = DateFormat(
      'EEE, d MMM \'at\' h:mm a',
    ).format(order.createdAt.toLocal());
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Infer discount if subtotal + fee + tax exceeds total
    final impliedDiscount =
        (order.subtotal + order.deliveryFee + order.tax) - order.total;
    final hasDiscount = impliedDiscount > 0.01;

    final addressParts = order.deliveryAddress.split(',');
    final primaryAddress = addressParts.isNotEmpty
        ? addressParts.first.trim()
        : order.deliveryAddress;
    final secondaryAddress = addressParts.length > 1
        ? addressParts.sublist(1).join(',').trim()
        : 'Delivery destination verified';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              safeTop + 72,
              20,
              safeBottom + 112,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Status & Overview Bento Card
                _EditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBgColor(order.status),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusBadgeText(order.status),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: _statusFgColor(order.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Order #SV-$shortId',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.33,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 15,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: AppColors.surfaceContainer,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showReceiptDialog(order, shortId),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.receipt_long,
                                  size: 20,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Journey Pill (for ongoing)
                      if (isOngoing) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withValues(
                              alpha: 0.60,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
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
                                              scale: 0.75 + p * 1.1,
                                              child: Opacity(
                                                opacity: (1 - p).clamp(
                                                  0.0,
                                                  0.75,
                                                ),
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color:
                                                            AppColors.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 9,
                                              height: 9,
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
                                  const SizedBox(width: 8),
                                  Text(
                                    order.status == 'out_for_delivery'
                                        ? 'On the way 🛵'
                                        : order.status == 'preparing'
                                        ? 'Chef is cooking 🔥'
                                        : 'Confirmed with kitchen ✅',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'ETA ~14 mins',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Payment Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              order.paymentStatus == 'paid'
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              size: 18,
                              color: order.paymentStatus == 'paid'
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.paymentMethod == 'cod'
                                    ? 'Cash on Delivery · Pay Rider at Door'
                                    : order.paymentStatus == 'paid'
                                    ? 'Paid via Card (Stripe •••• 4242)'
                                    : 'Card (Stripe) · Awaiting Webhook',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Restaurant Info Card
                _EditorialCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/images/biryani.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spice Craft Karachi',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.18,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Clifton Block 4 • Gourmet Mughlai',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.secondaryFixed.withValues(alpha: 0.50),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Dialing Spice Craft Karachi kitchen...',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.call,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Ordered Items Card
                _EditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            itemsAsync.when(
                              loading: () => 'Items Ordered',
                              error: (_, _) => 'Items Ordered',
                              data: (items) =>
                                  'Items Ordered (${items.length})',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              order.status == 'delivered'
                                  ? 'Completed'
                                  : 'All Prepared',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      itemsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        error: (_, _) => const Text('Could not load items.'),
                        data: (items) {
                          if (items.isEmpty) {
                            return const Text(
                              'No itemized records attached.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            );
                          }
                          return Column(
                            children: items.asMap().entries.map((entry) {
                              final item = entry.value;
                              final isLast = entry.key == items.length - 1;
                              final qty =
                                  (item['quantity'] as num?)?.toInt() ?? 1;
                              final price =
                                  (item['price'] as num?)?.toDouble() ?? 0.0;
                              final name = (item['name'] ?? 'Dish').toString();

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLast ? 0 : 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        color: AppColors.surfaceContainer,
                                        child: Image.asset(
                                          _assetForDishName(name),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${qty}x $name',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onSurface,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '\$${(price * qty).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '\$${price.toStringAsFixed(2)} each · Fresh kitchen prep',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Delivery & Rider Details Card
                _EditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Address Block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DELIVERY DESTINATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  primaryAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  secondaryAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nested Driver Lockup
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondaryFixed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining,
                                      size: 24,
                                      color: AppColors.onSecondaryFixed,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bilal Tariq',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '4.9',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '• Super Rider',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .onSurfaceVariant,
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
                            Row(
                              children: [
                                _MiniRiderBtn(
                                  icon: Icons.call,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Dialing rider Bilal Tariq...',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _MiniRiderBtn(
                                  icon: Icons.chat_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Opening chat with Bilal...',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Payment Breakdown Card (Bill Summary)
                _EditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bill Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow('Subtotal', order.subtotal),
                      const SizedBox(height: 8),
                      _SummaryRow('Delivery Fee', order.deliveryFee),
                      if (hasDiscount) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Special Discount (SAVORA20)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '-\$${impliedDiscount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (order.tax > 0) ...[
                        const SizedBox(height: 8),
                        _SummaryRow('Taxes & Fees', order.tax),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppColors.surfaceVariant,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Paid',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                'Includes all taxes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.33,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Preserved Delivery Confirmation for Active Orders
                if (isOngoing) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Confirm Order Delivered',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => confirmOrderDelivery(
                        context: context,
                        ref: ref,
                        orderId: order.id,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Support Help Link
                Center(
                  child: GestureDetector(
                    onTap: () => _showSupportDialog(shortId),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Need Help with this Order?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                      ),
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
                                    : context.go(AppRoutes.orderHistory),
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
                            'Order Detail',
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
                        onSelected: (val) {
                          if (val == 'refresh') {
                            ref.invalidate(orderItemsProvider(order.id));
                            ref.invalidate(orderEventsStreamProvider(order.id));
                          } else if (val == 'receipt') {
                            _showReceiptDialog(order, shortId);
                          } else if (val == 'reorder') {
                            reorderPastOrder(
                              context: context,
                              ref: ref,
                              orderId: order.id,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'refresh',
                            child: Text('Refresh Order'),
                          ),
                          PopupMenuItem(
                            value: 'receipt',
                            child: Text('Download Receipt'),
                          ),
                          PopupMenuItem(
                            value: 'reorder',
                            child: Text('Reorder Items'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sticky Bottom Live Action Dock
          Positioned(
            left: 20,
            right: 20,
            bottom: safeBottom + 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x381E1B19),
                        blurRadius: 40,
                        spreadRadius: -8,
                        offset: Offset(0, 20),
                      ),
                      BoxShadow(
                        color: Color(0x24F2602B),
                        blurRadius: 16,
                        spreadRadius: -4,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: isOngoing
                          ? () => context.push(
                              AppRoutes.orderTracking,
                              extra: order.id,
                            )
                          : () => reorderPastOrder(
                              context: context,
                              ref: ref,
                              orderId: order.id,
                            ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOngoing ? Icons.near_me : Icons.replay_rounded,
                            size: 22,
                            color: AppColors.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOngoing ? 'Track Live Delivery' : 'Reorder Items',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
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

  String _statusBadgeText(String status) {
    switch (status) {
      case 'confirmed':
      case 'preparing':
      case 'out_for_delivery':
        return 'DELIVERING NOW';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'cancelled':
        return AppColors.errorContainer;
      case 'delivered':
        return AppColors.surfaceContainerHigh;
      default:
        return AppColors.secondaryFixed;
    }
  }

  Color _statusFgColor(String status) {
    switch (status) {
      case 'cancelled':
        return AppColors.onErrorContainer;
      case 'delivered':
        return AppColors.onSurface;
      default:
        return AppColors.onSecondaryFixed;
    }
  }
}

class _EditorialCard extends StatelessWidget {
  final Widget child;

  const _EditorialCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
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
      child: child,
    );
  }
}

class _MiniRiderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniRiderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
        ),
      ],
    );
  }
}
