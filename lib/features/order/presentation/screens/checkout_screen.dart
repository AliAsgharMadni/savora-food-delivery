import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../addresses/presentation/controllers/address_providers.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../payment/presentation/controllers/payment_controller.dart';
import '../controllers/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController(
    text: 'Ocean Heights, Block 4, Sea View Road, Clifton, Karachi',
  );
  String _addressLabel = 'Home';
  String _addressApartment = 'Apt 402';
  bool _hasCustomAddress = false;
  bool _includeCutlery = true;
  bool _noContactDelivery = false;
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _fallbackAssetForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('pizza')) return 'assets/images/pizza.png';
    if (lower.contains('burger')) return 'assets/images/burger.png';
    return 'assets/images/biryani.png';
  }

  void _showEditAddressDialog() {
    final textCtrl = TextEditingController(text: _addressController.text);
    final aptCtrl = TextEditingController(text: _addressApartment);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                'Change Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: aptCtrl,
                decoration: InputDecoration(
                  labelText: 'Apt / Suite / Floor',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  onPressed: () {
                    if (textCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _hasCustomAddress = true;
                        _addressController.text = textCtrl.text.trim();
                        _addressApartment = aptCtrl.text.trim().isEmpty
                            ? 'Apt 402'
                            : aptCtrl.text.trim();
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Save Address',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _hasCustomAddress = false);
                    context.push(AppRoutes.savedAddresses);
                  },
                  icon: const Icon(Icons.bookmarks_outlined, size: 16),
                  label: const Text('Choose from Saved Addresses'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodPicker() {
    context.push(AppRoutes.paymentMethod);
  }

  Future<void> _handlePlaceOrder() async {
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    final selectedMethod = ref.read(selectedPaymentMethodProvider);
    final apiPaymentMethod = selectedMethod == 'cod' ? 'cod' : 'card';

    try {
      final prefsNotes = <String>[
        if (_includeCutlery) 'Cutlery included',
        if (_noContactDelivery) 'No-contact drop',
      ];
      final noteSuffix = prefsNotes.isEmpty ? '' : ' (${prefsNotes.join(', ')})';
      final fullAddress =
          '$_addressLabel ($_addressApartment), ${_addressController.text.trim()}$noteSuffix';
      final order = await ref
          .read(orderCheckoutControllerProvider.notifier)
          .placeOrder(
            deliveryAddress: fullAddress,
            paymentMethod: apiPaymentMethod,
          );

      if (!mounted) return;

      if (order != null) {
        if (apiPaymentMethod == 'card') {
          context.push(
            AppRoutes.stripePayment,
            extra: order,
          );
        } else {
          context.go(
            AppRoutes.paymentSuccess,
            extra: order,
          );
        }
      } else {
        final errorState = ref.read(orderCheckoutControllerProvider);
        final msg = errorState.error?.toString() ?? 'Order placement failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final discount = ref.watch(cartDiscountProvider);
    final promoCode = ref.watch(cartPromoCodeProvider);
    final total = ref.watch(cartTotalProvider);
    final defaultAddr = ref.watch(defaultAddressProvider);
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final selectedWallet = ref.watch(selectedDigitalWalletProvider);
    final savedCard = ref.watch(savedCardInfoProvider);

    if (!_hasCustomAddress && defaultAddr != null) {
      _addressLabel = defaultAddr.title;
      _addressApartment = defaultAddr.city;
      _addressController.text = defaultAddr.formattedAddress;
    }

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Checkout Form
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              safeTop + 72,
              20,
              safeBottom + 124,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Delivery Address Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.18,
                        color: AppColors.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showEditAddressDialog,
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.secondaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.home,
                              color: AppColors.onSecondaryFixed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _addressLabel,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.outlineVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _addressApartment,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _addressController.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed
                                  .withValues(alpha: 0.60),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.moped,
                                  size: 16,
                                  color: AppColors.onPrimaryFixed,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '20–30 mins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onPrimaryFixed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 15,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Leave with security / call',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Payment Method Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.18,
                        color: AppColors.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPaymentMethodPicker,
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showPaymentMethodPicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (selectedMethod == 'card')
                                _MastercardLogoBadge()
                              else if (selectedMethod == 'wallet')
                                Container(
                                  width: 48,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                )
                              else
                                Container(
                                  width: 48,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryFixed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    color: AppColors.onSecondaryFixed,
                                    size: 20,
                                  ),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          selectedMethod == 'card'
                                              ? savedCard.brand
                                              : selectedMethod == 'wallet'
                                                  ? selectedWallet
                                                  : 'Cash on Delivery',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        if (selectedMethod == 'card') ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '•••• ${savedCard.last4}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.tertiary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedMethod == 'card'
                                          ? 'Expires ${savedCard.expiry}'
                                          : selectedMethod == 'wallet'
                                              ? 'Instant digital wallet checkout'
                                              : 'Pay at your door upon delivery',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.tertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer
                                .withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Delivery Preferences Section
                const Text(
                  'Delivery Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.18,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Cutlery Custom Toggle Row
                      InkWell(
                        onTap: () =>
                            setState(() => _includeCutlery = !_includeCutlery),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      size: 22,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Include Cutlery & Napkins',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Eco-friendly disposables',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.tertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Custom w-12 h-7 Pill Toggle
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 28,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _includeCutlery
                                      ? AppColors.primary
                                      : AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: _includeCutlery
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.14),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          height: 1,
                          color: AppColors.surfaceContainer,
                        ),
                      ),
                      // No-contact Delivery Custom Checkbox Row
                      InkWell(
                        onTap: () => setState(
                          () => _noContactDelivery = !_noContactDelivery,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.door_front_door_outlined,
                                      size: 22,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'No-contact delivery',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Rider will drop off outside your door',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.tertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Custom w-6 h-6 rounded square checkbox
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _noContactDelivery
                                      ? AppColors.primary
                                      : AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _noContactDelivery
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: AppColors.onPrimary,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Order Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Summary (${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.18,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Savora Feast',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...cartItems.map((item) {
                        final fallback =
                            _fallbackAssetForCategory(item.food.category);
                        final imgUrl = item.food.imageUrl.trim();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: imgUrl.isEmpty
                                            ? Image.asset(
                                                fallback,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                imgUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    Image.asset(
                                                  fallback,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.food.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: ${item.quantity} · Fresh Prep',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.tertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppColors.surfaceContainer,
                        ),
                      ),
                      _CostLine(
                        label: 'Subtotal',
                        value: '\$${subtotal.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _CostLine(
                        label: 'Delivery Fee',
                        value: '\$${deliveryFee.toStringAsFixed(2)}',
                      ),
                      if (discount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Voucher (${promoCode ?? 'SAVORA20'} - 20%)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '-\$${discount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppColors.surfaceContainer,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
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
                                onTap: () => context.pop(),
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
                            'Checkout',
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
                        onSelected: (value) {
                          if (value == 'addresses') {
                            setState(() => _hasCustomAddress = false);
                            context.push(AppRoutes.savedAddresses);
                          } else if (value == 'payment') {
                            _showPaymentMethodPicker();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'addresses',
                            child: Text('Saved Addresses'),
                          ),
                          PopupMenuItem(
                            value: 'payment',
                            child: Text('Switch Payment Method'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pinned Frosted Bottom CTA Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottom + 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.90),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x141E1B19),
                        blurRadius: 24,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL TO PAY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.tertiary,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.33,
                              height: 1.15,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: (_isPlacingOrder || cartItems.isEmpty)
                                ? AppColors.primary.withValues(alpha: 0.65)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: (_isPlacingOrder || cartItems.isEmpty)
                                  ? null
                                  : _handlePlaceOrder,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: _isPlacingOrder
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.onPrimary,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Confirming Feast...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                size: 20,
                                                color: AppColors.onPrimary,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Place Order',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.onPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColors.onPrimary
                                                  .withValues(alpha: 0.20),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              size: 20,
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

class _MastercardLogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 16,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB001B).withValues(alpha: 0.90),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF79E1B).withValues(alpha: 0.90),
                    shape: BoxShape.circle,
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

class _CostLine extends StatelessWidget {
  final String label;
  final String value;

  const _CostLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.tertiary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
