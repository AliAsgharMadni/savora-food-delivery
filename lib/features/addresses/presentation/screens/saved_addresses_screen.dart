import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../data/models/saved_address.dart';
import '../controllers/address_providers.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  final _client = Supabase.instance.client;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteAddress(SavedAddress addr) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(ctx).padding.bottom + 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  size: 26,
                  color: AppColors.onErrorContainer,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Remove "${addr.title}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can easily add this address back whenever you\'re craving a feast.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer,
                          foregroundColor: AppColors.onSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          'Keep It',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.onError,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );

    if (confirmed == true) {
      try {
        await _client.from('addresses').delete().eq('id', addr.id);
        ref.invalidate(savedAddressesProvider);
      } catch (e) {
        _showError('Failed to delete address: $e');
      }
    }
  }

  Future<void> _setDefault(SavedAddress addr) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', user.id);
      await _client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addr.id);
      ref.invalidate(savedAddressesProvider);
    } catch (e) {
      _showError('Failed to set default address: $e');
    }
  }

  Future<void> _showAddressForm({SavedAddress? existing}) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl =
        TextEditingController(text: existing?.title ?? 'Home');
    final streetCtrl = TextEditingController(text: existing?.street ?? '');
    final cityCtrl =
        TextEditingController(text: existing?.city ?? 'Karachi');
    final stateCtrl = TextEditingController(text: existing?.state ?? '');
    final postalCtrl =
        TextEditingController(text: existing?.postalCode ?? '');
    bool isDefault = existing?.isDefault ?? true;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
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
                Text(
                  existing == null ? 'Add New Address' : 'Edit Address',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _FormField(
                  controller: titleCtrl,
                  label: 'Label (e.g. Home, Office)',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Label is required' : null,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: streetCtrl,
                  label: 'Street / Apt / Building',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Street address is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _FormField(
                        controller: cityCtrl,
                        label: 'City',
                        icon: Icons.location_city_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'City is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FormField(
                        controller: postalCtrl,
                        label: 'Postal Code',
                        icon: Icons.markunread_mailbox_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: stateCtrl,
                  label: 'Delivery Note / Area (optional)',
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setModal(() => isDefault = !isDefault),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Set as default delivery spot',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: isDefault,
                          onChanged: (v) => setModal(() => isDefault = v),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
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
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final user = ref.read(currentUserProvider);
                            if (user == null) return;

                            setModal(() => isSaving = true);
                            try {
                              if (isDefault) {
                                await _client
                                    .from('addresses')
                                    .update({'is_default': false})
                                    .eq('user_id', user.id);
                              }

                              final data = {
                                'user_id': user.id,
                                'title': titleCtrl.text.trim(),
                                'street': streetCtrl.text.trim(),
                                'city': cityCtrl.text.trim(),
                                'state': stateCtrl.text.trim().isEmpty
                                    ? null
                                    : stateCtrl.text.trim(),
                                'postal_code': postalCtrl.text.trim().isEmpty
                                    ? null
                                    : postalCtrl.text.trim(),
                                'is_default': isDefault,
                              };

                              if (existing != null) {
                                await _client
                                    .from('addresses')
                                    .update(data)
                                    .eq('id', existing.id);
                              } else {
                                await _client.from('addresses').insert(data);
                              }

                              ref.invalidate(savedAddressesProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setModal(() => isSaving = false);
                              _showError('Could not save address: $e');
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            existing == null
                                ? 'Save Address'
                                : 'Update Address',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(savedAddressesProvider);
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            child: addressesAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.only(top: safeTop + 64),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Padding(
                padding: EdgeInsets.only(top: safeTop + 64),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading addresses: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                          ),
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
                          onPressed: () =>
                              ref.invalidate(savedAddressesProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return _buildEmpty(safeTop, safeBottom);
                }

                SavedAddress defaultAddr = addresses.first;
                for (final a in addresses) {
                  if (a.isDefault) {
                    defaultAddr = a;
                    break;
                  }
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  edgeOffset: safeTop + 64,
                  onRefresh: () async =>
                      ref.invalidate(savedAddressesProvider),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      safeTop + 72,
                      20,
                      safeBottom + 116,
                    ),
                    children: [
                      // 1. Subtle Delivery Context Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed
                              .withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
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
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.near_me,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Delivering to ${defaultAddr.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '${defaultAddr.city} • 25-35 min',
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Section Header / Counter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Delivery Spots',
                            style: TextStyle(
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
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${addresses.length} saved',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. Address Cards List
                      ...addresses.map(
                        (addr) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _AddressCard(
                            address: addr,
                            onEdit: () => _showAddressForm(existing: addr),
                            onDelete: () => _deleteAddress(addr),
                            onSetDefault: () => _setDefault(addr),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 4. Delighter / Rider Pinpoint Accuracy Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.two_wheeler,
                                size: 20,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rider Pinpoint Accuracy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Pin addresses with precision so warm dishes arrive straight to your hands.',
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
                    ],
                  ),
                );
              },
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
                                onTap: () => Navigator.pop(context),
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
                            'Saved Addresses',
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
                          if (val == 'add') {
                            _showAddressForm();
                          } else if (val == 'refresh') {
                            ref.invalidate(savedAddressesProvider);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'add',
                            child: Text('Add New Address'),
                          ),
                          PopupMenuItem(
                            value: 'refresh',
                            child: Text('Refresh List'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sticky Bottom Full-Width Floating Pill CTA
          Positioned(
            left: 20,
            right: 20,
            bottom: safeBottom + 20,
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
                      onTap: () => _showAddressForm(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_location_alt,
                            size: 24,
                            color: AppColors.onPrimary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add New Address',
                            style: TextStyle(
                              fontSize: 18,
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

  Widget _buildEmpty(double safeTop, double safeBottom) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, safeTop + 64, 24, safeBottom + 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_location_alt_outlined,
                size: 38,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No saved addresses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your home or office spot for faster checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final lowerTitle = address.title.toLowerCase();
    final isHome = lowerTitle.contains('home');
    final isOffice =
        lowerTitle.contains('work') || lowerTitle.contains('office');

    final iconData = isHome
        ? Icons.home
        : isOffice
            ? Icons.work
            : Icons.pin_drop;

    final iconBg = address.isDefault
        ? AppColors.primary
        : isOffice
            ? AppColors.secondaryFixed
            : AppColors.tertiaryFixed;

    final iconFg = address.isDefault
        ? AppColors.onPrimary
        : isOffice
            ? AppColors.onSecondaryFixedVariant
            : AppColors.onTertiaryFixed;

    final subtitle = address.isDefault
        ? 'Primary delivery spot'
        : isOffice
            ? 'Workday orders'
            : 'Saved delivery location';

    final typeLabel = isOffice
        ? 'Commercial Hub'
        : isHome
            ? 'Apt • Door Drop'
            : 'Residential Villa';

    final typeIcon = isOffice
        ? Icons.corporate_fare
        : isHome
            ? Icons.doorbell
            : Icons.cottage;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: address.isDefault ? 0.06 : 0.03),
            blurRadius: address.isDefault ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                        boxShadow: address.isDefault
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(iconData, size: 22, color: iconFg),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                address.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.18,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if (address.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 13,
                                        color: AppColors.onPrimaryFixedVariant,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              AppColors.onPrimaryFixedVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (address.isDefault)
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
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.onPrimary,
                  ),
                )
              else
                Material(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onSetDefault,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radio_button_unchecked,
                            size: 14,
                            color: AppColors.onSurface,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Set Default',
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
            ],
          ),
          const SizedBox(height: 12),

          // Street Address Line
          Text(
            '${address.street}, ${address.city}${address.postalCode != null && address.postalCode!.isNotEmpty ? ' ${address.postalCode}' : ''}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.55,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),

          // Delivery Note Callout or Distance Hint
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  address.state != null && address.state!.trim().isNotEmpty
                      ? (isOffice ? Icons.desk : Icons.notes)
                      : Icons.navigation,
                  size: 18,
                  color: isOffice ? AppColors.secondary : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.state != null && address.state!.trim().isNotEmpty
                        ? '“${address.state!.trim()}”'
                        : 'Verified delivery zone · Fast rider dispatch',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: address.state != null &&
                              address.state!.trim().isNotEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions Toolbar (NO Divider)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(typeIcon, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Material(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: onEdit,
                      child: const SizedBox(
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.onSurface,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
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
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: AppColors.errorContainer,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDelete,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
