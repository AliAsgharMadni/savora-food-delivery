import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/savora_floating_nav.dart';
import '../../../../core/widgets/savora_tab_header.dart';
import '../../../addresses/presentation/controllers/address_providers.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../food/presentation/controllers/food_providers.dart';
import '../../../order/presentation/controllers/order_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final AnimationController _pulseController;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  bool _promoAlertsEnabled = true;
  bool _orderStatusAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(
    String userId,
    String email,
    BuildContext sheetContext,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final currentProfile = ref.read(userProfileProvider).value;

      final updated = (currentProfile != null)
          ? currentProfile.copyWith(
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
            )
          : UserProfile(
              id: userId,
              email: email,
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
            );

      await repository.updateProfile(updated);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        if (sheetContext.mounted) Navigator.pop(sheetContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showEditProfileSheet(String userId, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
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
                'Edit Personal Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hintText: 'e.g. +92 300 1234567',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              AuthButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: () => _saveProfile(userId, email, ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              const SizedBox(height: 18),
              const Text(
                'Notifications & Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text(
                  'Live Order Alerts',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Kitchen & rider arrival updates',
                  style: TextStyle(fontSize: 12),
                ),
                value: _orderStatusAlertsEnabled,
                onChanged: (v) {
                  setModalState(() => _orderStatusAlertsEnabled = v);
                  setState(() => _orderStatusAlertsEnabled = v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text(
                  'SAVORA20 & Gourmet Offers',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Seasonal dishes & exclusive Gold perks',
                  style: TextStyle(fontSize: 12),
                ),
                value: _promoAlertsEnabled,
                onChanged: (v) {
                  setModalState(() => _promoAlertsEnabled = v);
                  setState(() => _promoAlertsEnabled = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '24/7 Savora Support',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Our concierge team is live to help with deliveries, refunds, or kitchen notes.',
          style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
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
                  content: Text('Savora live chat specialist connected!'),
                  backgroundColor: AppColors.onSurface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Start Live Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final orders = ref.watch(userOrdersProvider).valueOrNull ?? const [];
    final favorites = ref.watch(favoritesProvider);
    final addresses = ref.watch(savedAddressesProvider).valueOrNull ?? const [];
    final cartCount = ref.watch(cartItemCountProvider);

    final activeOrdersCount = orders
        .where(
          (o) =>
              o.status == 'pending' ||
              o.status == 'confirmed' ||
              o.status == 'preparing' ||
              o.status == 'out_for_delivery',
        )
        .length;

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final profile = profileAsync.valueOrNull;
    if (_nameController.text.isEmpty && profile?.fullName != null) {
      _nameController.text = profile!.fullName!;
    }
    if (_phoneController.text.isEmpty && profile?.phone != null) {
      _phoneController.text = profile!.phone!;
    }

    final email = currentUser?.email ?? 'savora.guest@example.com';
    final displayName = (profile?.fullName?.trim().isNotEmpty == true)
        ? profile!.fullName!.trim()
        : 'Savora Member';
    final phoneDisplay = (profile?.phone?.trim().isNotEmpty == true)
        ? profile!.phone!.trim()
        : 'Tap edit to add phone';
    final userInitial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'S');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Dashboard
          Positioned.fill(
            child: profileAsync.isLoading && profile == null
                ? Padding(
                    padding: EdgeInsets.only(top: safeTop + 64),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      safeTop + 72,
                      20,
                      safeBottom + 116,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Profile Header Hero Card
                        Container(
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -42,
                                  right: -42,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.secondaryContainer
                                          .withValues(alpha: 0.22),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Identity Row
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Avatar with Edit Pencil Badge
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: 80,
                                                height: 80,
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .surfaceContainerHigh,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                        alpha: 0.06,
                                                      ),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        AppColors.primary,
                                                        AppColors
                                                            .primaryContainer,
                                                      ],
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    userInitial,
                                                    style: const TextStyle(
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.onPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Material(
                                                  color: AppColors.primary,
                                                  shape: const CircleBorder(),
                                                  elevation: 3,
                                                  child: InkWell(
                                                    customBorder:
                                                        const CircleBorder(),
                                                    onTap: () =>
                                                        _showEditProfileSheet(
                                                      currentUser?.id ?? '',
                                                      email,
                                                    ),
                                                    child: const SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: Icon(
                                                        Icons.edit,
                                                        size: 15,
                                                        color:
                                                            AppColors.onPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),

                                          // Identity Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        displayName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: -0.18,
                                                          color: AppColors
                                                              .onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .secondaryContainer
                                                            .withValues(
                                                          alpha: 0.40,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.verified,
                                                            size: 14,
                                                            color: AppColors
                                                                .onSecondaryContainer,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Verified',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .onSecondaryContainer,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  email,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.call,
                                                      size: 14,
                                                      color: AppColors.tertiary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        phoneDisplay,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .onSurfaceVariant
                                                              .withValues(
                                                            alpha: 0.85,
                                                          ),
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
                                      const SizedBox(height: 16),

                                      // Savora Gold Member Perk Tier Ribbon
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'SAVORA20 20% cashback perk is active on all orders!',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor:
                                                  AppColors.onSurface,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.secondaryFixed,
                                                AppColors.primaryFixed,
                                                AppColors.secondaryFixedDim
                                                    .withValues(alpha: 0.55),
                                              ],
                                            ),
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .surfaceContainerLowest
                                                            .withValues(
                                                          alpha: 0.85,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.workspace_premium,
                                                        size: 18,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Savora Gold Member',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .onPrimaryFixed,
                                                            ),
                                                          ),
                                                          Text(
                                                            '20% Cashback active on all gourmet orders',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppColors
                                                                  .onSecondaryFixedVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 18,
                                                color: AppColors
                                                    .onSecondaryFixedVariant,
                                              ),
                                            ],
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
                        const SizedBox(height: 16),

                        // 2. Quick Stats 3-Column Bento Banner
                        Container(
                          padding: const EdgeInsets.all(8),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: _QuickStatTile(
                                  value: '${orders.length}',
                                  label: 'Orders Placed',
                                  valueColor: AppColors.primary,
                                  onTap: () =>
                                      context.push(AppRoutes.orderHistory),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _QuickStatTile(
                                  value: '${favorites.length}',
                                  label: 'Favorite Spots',
                                  valueColor: AppColors.secondary,
                                  onTap: () => context.go(AppRoutes.home),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: _QuickStatTile(
                                  value: '\$12.50',
                                  label: 'Wallet Balance',
                                  valueColor: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Account & Activity Navigation
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ACCOUNT & ACTIVITY',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.tertiary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showEditProfileSheet(
                                  currentUser?.id ?? '',
                                  email,
                                ),
                                child: const Text(
                                  'Preferences',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BentoMenuCard(
                          children: [
                            _ProfileMenuRow(
                              icon: Icons.receipt_long,
                              iconBg: AppColors.secondaryContainer
                                  .withValues(alpha: 0.30),
                              iconColor: AppColors.onSecondaryContainer,
                              title: 'Order History',
                              subtitle: 'View past food orders & reorder',
                              badgeText: activeOrdersCount > 0
                                  ? '$activeOrdersCount Active'
                                  : null,
                              badgeBg: AppColors.primary.withValues(alpha: 0.10),
                              badgeFg: AppColors.primary,
                              onTap: () =>
                                  context.push(AppRoutes.orderHistory),
                            ),
                            _ProfileMenuRow(
                              icon: Icons.location_on,
                              iconBg: AppColors.surfaceContainerHigh,
                              iconColor: AppColors.onSurface,
                              title: 'Saved Addresses',
                              subtitle: 'Home, office, and delivery points',
                              badgeText: addresses.isNotEmpty
                                  ? '${addresses.length} Saved'
                                  : null,
                              badgeBg: AppColors.surfaceContainerHigh,
                              badgeFg: AppColors.onSurfaceVariant,
                              onTap: () =>
                                  context.push(AppRoutes.savedAddresses),
                            ),
                            _ProfileMenuRow(
                              icon: Icons.account_balance_wallet,
                              iconBg: AppColors.secondaryContainer
                                  .withValues(alpha: 0.20),
                              iconColor: AppColors.secondary,
                              title: 'Payment Methods',
                              subtitle: 'Cards, JazzCash & Cash options',
                              onTap: () =>
                                  context.push(AppRoutes.paymentMethod),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 4. Support & Alerts Navigation
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'SUPPORT & ALERTS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.tertiary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _BentoMenuCard(
                          children: [
                            _ProfileMenuRow(
                              icon: Icons.notifications_active,
                              iconBg: AppColors.primaryFixed,
                              iconColor: AppColors.primary,
                              title: 'Notifications & Offers',
                              subtitle: 'Manage alerts & promo updates',
                              onTap: _showNotificationsSheet,
                            ),
                            _ProfileMenuRow(
                              icon: Icons.support_agent,
                              iconBg: AppColors.surfaceContainer,
                              iconColor: AppColors.onSurface,
                              title: 'Help & Support',
                              subtitle: '24/7 Live chat assistance',
                              trailingPulse: _pulseController,
                              onTap: _showSupportDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 5. Log Out Session Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer
                                .withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _isLoggingOut
                                  ? null
                                  : () async {
                                      setState(() => _isLoggingOut = true);
                                      await ref
                                          .read(authControllerProvider.notifier)
                                          .signOut();
                                    },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoggingOut) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.onErrorContainer,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Logging out...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onErrorContainer,
                                      ),
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.logout,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onErrorContainer,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Fixed Frosted mobile_tab Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SavoraTabHeader(
              title: 'Profile',
              userInitial: userInitial,
            ),
          ),

          // Detached Floating Charcoal Navigation Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SavoraFloatingNav(
              currentIndex: 3,
              cartCount: cartCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final VoidCallback? onTap;

  const _QuickStatTile({
    required this.value,
    required this.label,
    required this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoMenuCard extends StatelessWidget {
  final List<Widget> children;

  const _BentoMenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
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
      child: Column(children: children),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;
  final AnimationController? trailingPulse;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeBg,
    this.badgeFg,
    this.trailingPulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeFg,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (trailingPulse != null) ...[
                FadeTransition(
                  opacity: Tween<double>(begin: 0.4, end: 1.0)
                      .animate(trailingPulse!),
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
              ],
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.tertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
