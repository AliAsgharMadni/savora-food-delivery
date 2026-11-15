import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../controllers/payment_controller.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  late String _selectedMethod;
  late String _selectedWallet;

  @override
  void initState() {
    super.initState();
    _selectedMethod = ref.read(selectedPaymentMethodProvider);
    _selectedWallet = ref.read(selectedDigitalWalletProvider);
  }

  String get _ctaLabel {
    switch (_selectedMethod) {
      case 'cod':
        return 'Confirm Cash on Delivery';
      case 'wallet':
        return 'Continue to Digital Wallet';
      case 'card':
      default:
        return 'Confirm Payment Method';
    }
  }

  void _showAddNewCardSheet() {
    final currentCard = ref.read(savedCardInfoProvider);
    final holderCtrl = TextEditingController(text: currentCard.holderName);
    final numberCtrl = TextEditingController(text: '4242');
    final expiryCtrl = TextEditingController(text: currentCard.expiry);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
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
              const SizedBox(height: 18),
              const Text(
                'Add New Card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Card details are encrypted with Stripe for future fast checkout.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: holderCtrl,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: numberCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: 'Last 4 Digits',
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: expiryCtrl,
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
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
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    final digits = numberCtrl.text.trim();
                    final last4 = digits.length >= 4
                        ? digits.substring(digits.length - 4)
                        : currentCard.last4;
                    ref.read(savedCardInfoProvider.notifier).state =
                        SavedCardInfo(
                      brand: last4.startsWith('4') ? 'Visa' : 'Mastercard',
                      last4: last4,
                      holderName: holderCtrl.text.trim().isEmpty
                          ? currentCard.holderName
                          : holderCtrl.text.trim(),
                      expiry: expiryCtrl.text.trim().isEmpty
                          ? currentCard.expiry
                          : expiryCtrl.text.trim(),
                    );
                    setState(() => _selectedMethod = 'card');
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Save Card',
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

  void _confirmSelection() {
    ref.read(selectedPaymentMethodProvider.notifier).state = _selectedMethod;
    ref.read(selectedDigitalWalletProvider.notifier).state = _selectedWallet;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedMethod == 'cod'
              ? 'Payment method set to Cash on Delivery'
              : _selectedMethod == 'wallet'
                  ? 'Payment method set to $_selectedWallet'
                  : 'Payment method set to Credit or Debit Card',
        ),
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (context.canPop()) {
      context.pop(_selectedMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedCard = ref.watch(savedCardInfoProvider);
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Payment Method Options
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              safeTop + 72,
              20,
              safeBottom + 128,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Subtitle / Contextual Guidance
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Select your preferred payment method for current and future gourmet orders.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

                // 1. Credit or Debit Card Option
                _PaymentSelectionCard(
                  isSelected: _selectedMethod == 'card',
                  onTap: () => setState(() => _selectedMethod = 'card'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Radio + Title + Network Emblems
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _RadioIndicator(
                                  isSelected: _selectedMethod == 'card',
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Credit or Debit Card',
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
                                        'Default choice',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mastercard overlapping circles
                                SizedBox(
                                  width: 24,
                                  height: 16,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEB001B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF79E1B)
                                                .withValues(alpha: 0.85),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Visa emblem
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1F71),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'VISA',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tactile Saved Card Surface Preview (#33302B dark charcoal)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.inverseSurface,
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              Color.alphaBlend(
                                AppColors.primary.withValues(alpha: 0.14),
                                AppColors.inverseSurface,
                              ),
                              AppColors.inverseSurface,
                              Color.alphaBlend(
                                AppColors.secondaryContainer
                                    .withValues(alpha: 0.16),
                                AppColors.inverseSurface,
                              ),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.contactless,
                                  size: 28,
                                  color: AppColors.secondaryContainer,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHighest
                                        .withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'PREFERRED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: AppColors.secondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '•••• •••• •••• ${savedCard.last4}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                                color: AppColors.inverseOnSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CARDHOLDER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppColors.tertiaryFixedDim,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      savedCard.holderName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.inverseOnSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'EXPIRES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppColors.tertiaryFixedDim,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      savedCard.expiry,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.inverseOnSurface,
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

                      // Action Row: + Add New Card Pill & Verified Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _showAddNewCardSheet,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add New Card',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.onSurfaceVariant,
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

                // 2. Cash on Delivery Option
                _PaymentSelectionCard(
                  isSelected: _selectedMethod == 'cod',
                  onTap: () => setState(() => _selectedMethod = 'cod'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _RadioIndicator(
                              isSelected: _selectedMethod == 'cod',
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash on Delivery',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.18,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Pay with exact cash or request rider change upon delivery.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments,
                              size: 26,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tip or notes for change can be specified at delivery',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Digital Wallets Option
                _PaymentSelectionCard(
                  isSelected: _selectedMethod == 'wallet',
                  onTap: () => setState(() => _selectedMethod = 'wallet'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _RadioIndicator(
                              isSelected: _selectedMethod == 'wallet',
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Digital Wallets',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.18,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Instant one-tap checkout',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _WalletChip(
                              label: 'JazzCash',
                              dotColor: AppColors.primary,
                              isSelected: _selectedMethod == 'wallet' &&
                                  _selectedWallet == 'JazzCash',
                              onTap: () => setState(() {
                                _selectedMethod = 'wallet';
                                _selectedWallet = 'JazzCash';
                              }),
                            ),
                            const SizedBox(width: 6),
                            _WalletChip(
                              label: 'Easypaisa',
                              dotColor: const Color(0xFF00A859),
                              isSelected: _selectedMethod == 'wallet' &&
                                  _selectedWallet == 'Easypaisa',
                              onTap: () => setState(() {
                                _selectedMethod = 'wallet';
                                _selectedWallet = 'Easypaisa';
                              }),
                            ),
                            const SizedBox(width: 6),
                            _WalletChip(
                              label: 'Apple Pay',
                              icon: Icons.phone_iphone,
                              isSelected: _selectedMethod == 'wallet' &&
                                  _selectedWallet == 'Apple Pay',
                              onTap: () => setState(() {
                                _selectedMethod = 'wallet';
                                _selectedWallet = 'Apple Pay';
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Safety & Security Guarantee Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safe & Encrypted',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.18,
                                color: AppColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '256-bit encrypted secure checkout. Your culinary payment information is strictly safeguarded.',
                              style: TextStyle(
                                fontSize: 12,
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
                            'Payment Method',
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
                          if (val == 'add_card') _showAddNewCardSheet();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'add_card',
                            child: Text('Add New Card'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Floating CTA Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withValues(alpha: 0.95),
                    AppColors.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _confirmSelection,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _ctaLabel,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSelectionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _PaymentSelectionCard({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 18 : 10,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;

  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.onPrimary : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _WalletChip({
    required this.label,
    this.dotColor,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: AppColors.inverseSurface,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                    isSelected ? AppColors.onPrimaryFixed : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

