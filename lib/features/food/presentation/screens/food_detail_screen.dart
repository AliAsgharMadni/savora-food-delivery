import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../data/models/food_item.dart';
import '../controllers/food_providers.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodItem food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  String _selectedSize = 'Medium';
  String _selectedSpice = '🌶️🌶️ Authentic Spicy';
  late final AnimationController _pulseController;

  static const List<String> _spiceOptions = [
    '🌶️ Mild',
    '🌶️🌶️ Authentic Spicy',
    '🔥 Extra Fiery',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _unitPriceForSize(String size) {
    final base = widget.food.price;
    switch (size) {
      case 'Small':
        return double.parse((base * 0.85).toStringAsFixed(2));
      case 'Large':
        return double.parse((base * 1.35).toStringAsFixed(2));
      case 'Medium':
      default:
        return base;
    }
  }

  String _fallbackAssetForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('pizza')) return 'assets/images/pizza.png';
    if (lower.contains('burger')) return 'assets/images/burger.png';
    return 'assets/images/biryani.png';
  }

  void _addToCart() {
    final selectedPrice = _unitPriceForSize(_selectedSize);
    final configuredItem = FoodItem(
      id: widget.food.id,
      restaurantId: widget.food.restaurantId,
      name: _selectedSize == 'Medium'
          ? widget.food.name
          : '${widget.food.name} ($_selectedSize)',
      description: widget.food.description,
      price: selectedPrice,
      imageUrl: widget.food.imageUrl,
      category: widget.food.category,
      rating: widget.food.rating,
      calories: widget.food.calories,
      prepTime: widget.food.prepTime,
      isPopular: widget.food.isPopular,
    );

    ref
        .read(cartProvider.notifier)
        .addToCart(configuredItem, quantity: _quantity);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added $_quantity× ${widget.food.name} ($_selectedSize) to cart',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: AppColors.secondaryFixed,
          onPressed: () => context.push(AppRoutes.cart),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.food.id);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider);

    final profileName = userProfile?.fullName?.trim() ?? '';
    final rawName =
        profileName.isNotEmpty ? profileName : (currentUser?.email ?? 'S');
    final userInitial = rawName.isNotEmpty ? rawName[0].toUpperCase() : 'S';

    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final unitPrice = _unitPriceForSize(_selectedSize);
    final totalPrice = unitPrice * _quantity;

    final aromaLabel = widget.food.category.toLowerCase().contains('biryani')
        ? 'Freshly Dum Cooked'
        : 'Freshly Prepared';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: EdgeInsets.only(top: topInset + 64),
            child: Stack(
              children: [
                // Top Food Hero Image (360px)
                SizedBox(
                  height: 360,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: 1.05,
                        child: _buildHeroImage(),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0x66000000),
                              Colors.transparent,
                              Color(0x4D000000),
                            ],
                          ),
                        ),
                      ),
                      // Floating Top Utility Pill Controls
                      Positioned(
                        top: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _FrostedCircleIcon(
                              icon: Icons.arrow_back,
                              iconColor: AppColors.onSurface,
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              },
                            ),
                            _FrostedCircleIcon(
                              icon: isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              iconColor: isFavorite
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              onTap: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(widget.food.id);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Bottom-Left Freshness / Aroma Tag
                      Positioned(
                        bottom: 48,
                        left: 20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1A1E1B19),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
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
                                  const SizedBox(width: 8),
                                  Text(
                                    aromaLabel,
                                    style: const TextStyle(
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
                    ],
                  ),
                ),

                // White Overlapping Detail Sheet (-32px overlap)
                Padding(
                  padding: const EdgeInsets.only(top: 328),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 168),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0F1E1B19),
                          blurRadius: 32,
                          offset: Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Centered Pull Handle Indicator
                        Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),

                        // Dish Title & Chef's Pick Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.food.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.food.isPopular
                                    ? '🔥 Chef\'s Pick'
                                    : '✨ House Special',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSecondaryFixed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Meta Row
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.food.prepTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.tertiaryFixedDim,
                              ),
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '1 generous portion',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.tertiaryFixedDim,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.food.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '(320 reviews)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.onSurfaceVariant,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Rich Description Paragraph
                        Text(
                          widget.food.description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                            height: 1.625,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Nutrition Breakdown
                        const Text(
                          'Nutrition Breakdown',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _NutritionTile(
                                icon: Icons.bolt,
                                iconColor: AppColors.primary,
                                value: '${widget.food.calories ?? 680}',
                                label: 'KCAL',
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: _NutritionTile(
                                icon: Icons.fitness_center,
                                iconColor: AppColors.secondary,
                                value: '42g',
                                label: 'PROTEIN',
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: _NutritionTile(
                                icon: Icons.grain,
                                iconColor: AppColors.onSecondaryContainer,
                                value: '78g',
                                label: 'CARBS',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Select Portion Size
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Portion Size',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'REQUIRED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _PortionCard(
                                label: 'Small',
                                price: _unitPriceForSize('Small'),
                                isSelected: _selectedSize == 'Small',
                                onTap: () =>
                                    setState(() => _selectedSize = 'Small'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PortionCard(
                                label: 'Medium',
                                price: _unitPriceForSize('Medium'),
                                isSelected: _selectedSize == 'Medium',
                                onTap: () =>
                                    setState(() => _selectedSize = 'Medium'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PortionCard(
                                label: 'Large',
                                price: _unitPriceForSize('Large'),
                                isSelected: _selectedSize == 'Large',
                                onTap: () =>
                                    setState(() => _selectedSize = 'Large'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Spice Level Selector
                        const Text(
                          'Spice Level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _spiceOptions.map((spice) {
                            final isSelected = _selectedSpice == spice;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSpice = spice),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryContainer
                                      : AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.22),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  spice,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed Frosted Top Header Bar (h-16 / 64px)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: topInset + 64,
                  padding: EdgeInsets.only(top: topInset, left: 16, right: 16),
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
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.home);
                                  }
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  size: 22,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryContainer,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Food Detail',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Share link copied for ${widget.food.name}!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.onSurface,
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.share_outlined,
                                  size: 20,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.profile),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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

          // Docked Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    border: const Border(
                      top: BorderSide(
                        color: AppColors.surfaceContainerHigh,
                        width: 1,
                      ),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x141E1B19),
                        blurRadius: 32,
                        offset: Offset(0, -12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quantity Stepper + Total Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed
                                  .withValues(alpha: 0.50),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StepperButton(
                                  icon: Icons.remove,
                                  backgroundColor: Colors.white,
                                  iconColor: _quantity > 1
                                      ? AppColors.onSurface
                                      : AppColors.tertiaryFixedDim,
                                  onTap: _quantity > 1
                                      ? () => setState(() => _quantity--)
                                      : null,
                                ),
                                SizedBox(
                                  width: 38,
                                  child: Text(
                                    '$_quantity',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                                _StepperButton(
                                  icon: Icons.add,
                                  backgroundColor: AppColors.primary,
                                  iconColor: Colors.white,
                                  onTap: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'TOTAL PRICE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '\$${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Custom 56px Add to Cart Pill Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.30),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _addToCart,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final fallback = _fallbackAssetForCategory(widget.food.category);
    final url = widget.food.imageUrl.trim();
    if (url.isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(fallback, fit: BoxFit.cover),
    );
  }
}

class _FrostedCircleIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _FrostedCircleIcon({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F1E1B19),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.white.withValues(alpha: 0.80),
            child: InkWell(
              onTap: onTap,
              child: Icon(icon, size: 22, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _NutritionTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortionCard extends StatelessWidget {
  final String label;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  const _PortionCard({
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryContainer.withValues(alpha: 0.40)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.80)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StepperButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
