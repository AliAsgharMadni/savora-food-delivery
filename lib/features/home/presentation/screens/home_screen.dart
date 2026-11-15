import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/savora_empty_states.dart';
import '../../../../core/widgets/savora_floating_nav.dart';
import '../../../../core/widgets/savora_tab_header.dart';
import '../../../addresses/presentation/controllers/address_providers.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../food/data/models/food_item.dart';
import '../../../food/presentation/controllers/food_providers.dart';
import '../../../order/presentation/controllers/order_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  static const List<Map<String, String>> _categories = [
    {'name': 'All', 'emoji': ''},
    {'name': 'Burgers', 'emoji': '🍔'},
    {'name': 'Biryani', 'emoji': '🥘'},
    {'name': 'Pizza', 'emoji': '🍕'},
    {'name': 'Desserts', 'emoji': '🍰'},
    {'name': 'Drinks', 'emoji': '🥤'},
    {'name': 'Pasta', 'emoji': '🍝'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _focusSearch() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        110,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _searchFocusNode.requestFocus();
  }

  void _showCategoryFilterSheet(String selectedCategory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(foodSearchQueryProvider.notifier).state = '';
                    ref.read(selectedCategoryProvider.notifier).state = 'All';
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final name = cat['name']!;
                final isSel = name == selectedCategory;
                return ChoiceChip(
                  label: Text(
                    cat['emoji']!.isEmpty ? name : '${cat['emoji']} $name',
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSel ? AppColors.onPrimary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) {
                    ref.read(selectedCategoryProvider.notifier).state = name;
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final foodsAsync = ref.watch(foodsListProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final defaultAddr = ref.watch(defaultAddressProvider);
    final ordersAsync = ref.watch(userOrdersProvider);
    final ongoingCount = ordersAsync.valueOrNull
            ?.where((o) =>
                o.status == 'pending' ||
                o.status == 'confirmed' ||
                o.status == 'preparing' ||
                o.status == 'out_for_delivery')
            .length ??
        0;

    final displayName = profileAsync.value?.fullName?.isNotEmpty == true
        ? profileAsync.value!.fullName!
        : (currentUser?.email?.split('@').first ?? 'Foodie');

    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scroll Feed
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: safeTop + 64, // clearance for 64px frosted header
              bottom: 112, // pb-28 for floating pill nav
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Bar Row: Avatar + Location Picker + Notifications Bell
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push(AppRoutes.savedAddresses),
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryFixed,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFF2602B)
                                                  .withAlpha(31),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors
                                                  .onSecondaryFixedVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.surfaceBright,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          defaultAddr != null
                                              ? 'DELIVER TO (${defaultAddr.title.toUpperCase()})'
                                              : 'DELIVER TO',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            height: 14 / 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                defaultAddr?.city ??
                                                    'Karachi, Pakistan',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  height: 24 / 18,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.18,
                                                  color: AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.expand_more,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          defaultAddr?.street ??
                                              'Clifton Block 4, Sea View Rd',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 16 / 12,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.12,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Notification Bell Elevated Button (opens Order History)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push(AppRoutes.orderHistory),
                              borderRadius: BorderRadius.circular(9999),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.onTertiaryFixed
                                          .withAlpha(15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications_outlined,
                                      size: 22,
                                      color: AppColors.onSurface,
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.surfaceBright,
                                            width: 2,
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
                      ),
                    ),

                    // 2. Main Headline
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Text(
                        'What are you craving today?',
                        style: TextStyle(
                          fontSize: 28,
                          height: 34 / 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.56,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),

                    // 3. Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF2602B).withAlpha(20),
                              blurRadius: 24,
                              spreadRadius: -4,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.onTertiaryFixed.withAlpha(10),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Icon(
                                Icons.search,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: (val) {
                                  ref
                                      .read(foodSearchQueryProvider.notifier)
                                      .state = val;
                                },
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurface,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Search biryani, burgers, pizza...',
                                  hintStyle: TextStyle(
                                    color: AppColors.outline,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  filled: true,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _showCategoryFilterSheet(selectedCategory),
                                borderRadius: BorderRadius.circular(9999),
                                child: Ink(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    size: 20,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. Category Pills (Horizontal Scroll)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = _categories[index];
                            final catName = item['name']!;
                            final emoji = item['emoji']!;
                            final isSelected = catName == selectedCategory;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state = catName;
                                },
                                borderRadius: BorderRadius.circular(9999),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(9999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.primary.withAlpha(71)
                                            : AppColors.onTertiaryFixed
                                                .withAlpha(10),
                                        blurRadius: isSelected ? 16 : 12,
                                        offset: Offset(0, isSelected ? 6 : 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (catName == 'All') ...[
                                        Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 14,
                                          color: isSelected
                                              ? AppColors.onPrimary
                                              : AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                      ] else if (emoji.isNotEmpty) ...[
                                        Text(
                                          emoji,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        catName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 16 / 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.24,
                                          color: isSelected
                                              ? AppColors.onPrimary
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 5. Promo Banner (rounded-xl = 48px)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(48), // rounded-xl
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryContainer, // #ce4711
                              AppColors.primary, // #a83300
                              AppColors.secondary, // #875227
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryContainer.withAlpha(77),
                              blurRadius: 36,
                              spreadRadius: -6,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative Circles
                            Positioned(
                              right: -40,
                              bottom: -40,
                              child: Container(
                                width: 176,
                                height: 176,
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimary.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16,
                              top: 8,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimary.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),

                            // Text Stack
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: FractionallySizedBox(
                                widthFactor: 0.72,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.onPrimary.withAlpha(51),
                                        borderRadius:
                                            BorderRadius.circular(9999),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_offer,
                                            color: AppColors.onPrimary,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'SPECIAL TREAT',
                                            style: TextStyle(
                                              fontSize: 10,
                                              height: 14 / 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              color: AppColors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'First order 20% off',
                                      style: TextStyle(
                                        fontSize: 22,
                                        height: 26 / 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.33,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Savor signature flavors straight to your doorstep in minutes.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.primaryFixed,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'Use Code:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryFixed,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceBright,
                                            borderRadius:
                                                BorderRadius.circular(9999),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(20),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'SAVORA20',
                                            style: TextStyle(
                                              fontSize: 12,
                                              height: 16 / 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Translucent Circle Badge ("20% OFF")
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.onPrimary.withAlpha(38),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '20%',
                                          style: TextStyle(
                                            fontSize: 22,
                                            height: 1.0,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                        Text(
                                          'OFF',
                                          style: TextStyle(
                                            fontSize: 10,
                                            height: 14 / 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: AppColors.onPrimary,
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
                      ),
                    ),

                    // 6. Section: Popular Now
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Popular Now',
                                      style: TextStyle(
                                        fontSize: 22,
                                        height: 28 / 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.33,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Top picks loved by your neighborhood',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _searchController.clear();
                                  ref
                                      .read(foodSearchQueryProvider.notifier)
                                      .state = '';
                                  ref
                                      .read(selectedCategoryProvider.notifier)
                                      .state = 'All';
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: const Row(
                                  children: [
                                    Text(
                                      'See All',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dish Cards Stack
                          foodsAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            error: (e, _) =>
                                Center(child: Text('Error loading dishes: $e')),
                            data: (foods) {
                              if (foods.isEmpty) {
                                return SavoraNoSearchView(
                                  query: _searchController.text,
                                  onBrowseAll: () {
                                    _searchController.clear();
                                    ref
                                        .read(foodSearchQueryProvider.notifier)
                                        .state = '';
                                    ref
                                        .read(selectedCategoryProvider.notifier)
                                        .state = 'All';
                                  },
                                  onSelectSuggestion: (tag) {
                                    _searchController.text = tag;
                                    ref
                                        .read(selectedCategoryProvider.notifier)
                                        .state = 'All';
                                    ref
                                        .read(foodSearchQueryProvider.notifier)
                                        .state = tag;
                                  },
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: foods.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 24), // gap-space-lg
                                itemBuilder: (context, index) {
                                  final food = foods[index];
                                  return _FoodCard(
                                    food: food,
                                    showPromoTag: index == 0 || food.isPopular,
                                    onTap: () => context.push(
                                      AppRoutes.foodDetail,
                                      extra: food,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Frosted Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SavoraTabHeader(
              title: 'Home',
              userInitial: displayName,
              hasNotificationBadge: ongoingCount > 0,
              onNotificationTap: () => context.push(AppRoutes.orderHistory),
            ),
          ),

          // Floating Charcoal Bottom Pill Navigation Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SavoraFloatingNav(
              currentIndex: 0,
              cartCount: cartCount,
              onSearchTap: _focusSearch,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCard extends ConsumerWidget {
  final FoodItem food;
  final bool showPromoTag;
  final VoidCallback onTap;

  const _FoodCard({
    required this.food,
    required this.showPromoTag,
    required this.onTap,
  });

  String? _fallbackAsset(String category) {
    final c = category.toLowerCase();
    if (c.contains('biryani')) return 'assets/images/biryani.png';
    if (c.contains('pizza')) return 'assets/images/pizza.png';
    if (c.contains('burger')) return 'assets/images/burger.png';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(food.id);
    final fallback = _fallbackAsset(food.category);
    final oldPrice = food.price * 1.25;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32), // rounded-lg
      child: Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32), // rounded-lg
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2602B).withAlpha(20),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.onTertiaryFixed.withAlpha(10),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Full-Width 192px Image Container
            SizedBox(
              height: 192, // h-48
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16), // rounded-[16px]
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.surfaceContainer,
                      child: Image.network(
                        food.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback != null
                            ? Image.asset(fallback, fit: BoxFit.cover)
                            : const Center(
                                child: Icon(
                                  Icons.restaurant,
                                  size: 48,
                                  color: AppColors.outline,
                                ),
                              ),
                      ),
                    ),

                    // 20% Off Tag (top-3 left-3)
                    if (showPromoTag)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(89),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 14,
                                color: AppColors.onPrimary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '20% off',
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 14 / 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Favorite Heart Button (top-3 right-3)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(food.id),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest
                                    .withAlpha(230),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: isFav
                                    ? AppColors.primary
                                    : AppColors.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Delivery Time Badge (bottom-3 left-3)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inverseSurface.withAlpha(204),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppColors.secondaryFixed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  food.prepTime,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 14 / 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inverseOnSurface,
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
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 24 / 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.18,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              food.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                height: 14 / 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${food.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              height: 28 / 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.33,
                              color: AppColors.primary,
                            ),
                          ),
                          if (showPromoTag) ...[
                            const SizedBox(width: 6),
                            Text(
                              '\$${oldPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.outline,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Quick Add + Circle Button (40x40)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ref.read(cartProvider.notifier).addToCart(food);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: AppColors.secondaryFixed,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('${food.name} added!'),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.inverseSurface,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(9999),
                          child: Ink(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(82),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 22,
                              color: AppColors.onPrimary,
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
      ),
    );
  }
}
