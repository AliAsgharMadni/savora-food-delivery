import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../food/data/models/food_item.dart';
import '../../../food/presentation/controllers/food_providers.dart';
import '../../data/models/order.dart';
import '../../data/order_repository.dart';

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  return SupabaseOrderRepository();
});

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return repository.streamUserOrders(user.id);
});

final orderByIdProvider =
    FutureProvider.autoDispose.family<OrderModel?, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchOrderById(orderId);
});

final orderStreamProvider =
    StreamProvider.autoDispose.family<OrderModel?, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.streamOrder(orderId);
});

final orderItemsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchOrderItems(orderId);
});

final orderEventsStreamProvider =
    StreamProvider.family<List<OrderEvent>, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.streamOrderEvents(orderId);
});

/// Shared helper to confirm order delivery via backend and refresh state.
Future<bool> confirmOrderDelivery({
  required BuildContext context,
  required WidgetRef ref,
  required String orderId,
}) async {
  try {
    await ref.read(orderRepositoryProvider).confirmDelivery(orderId);
    ref.invalidate(userOrdersProvider);
    ref.invalidate(orderStreamProvider(orderId));
    ref.invalidate(orderByIdProvider(orderId));
    ref.invalidate(orderEventsStreamProvider(orderId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as Delivered! Enjoy your meal 🎉'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not confirm delivery: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}

/// Shared helper to advance an active order to its next delivery stage.
Future<void> advanceOrderStage({
  required BuildContext context,
  required WidgetRef ref,
  required String orderId,
}) async {
  try {
    await ref.read(orderRepositoryProvider).advanceDeliveryStage(orderId);
    ref.invalidate(userOrdersProvider);
    ref.invalidate(orderStreamProvider(orderId));
    ref.invalidate(orderByIdProvider(orderId));
    ref.invalidate(orderEventsStreamProvider(orderId));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update stage: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Shared helper to repopulate the cart from a past order's items and open Cart.
Future<void> reorderPastOrder({
  required BuildContext context,
  required WidgetRef ref,
  required String orderId,
}) async {
  try {
    final orderRepo = ref.read(orderRepositoryProvider);
    final foodRepo = ref.read(foodRepositoryProvider);
    final items = await orderRepo.fetchOrderItems(orderId);

    if (items.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items found to reorder for this order.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final cartNotifier = ref.read(cartProvider.notifier);
    for (final row in items) {
      final foodId = row['food_id'] as String?;
      FoodItem? food;
      if (foodId != null) {
        food = await foodRepo.fetchFoodById(foodId);
      }
      food ??= FoodItem(
        id: foodId ?? (row['id'] as String? ?? DateTime.now().toIso8601String()),
        name: (row['name'] as String?) ?? 'Dish',
        description: 'Reordered favorite',
        price: ((row['price'] as num?) ?? 0.0).toDouble(),
        imageUrl: '',
        category: 'Reorder',
        rating: 4.8,
        prepTime: '15-20 min',
        isPopular: false,
      );
      final qty = (row['quantity'] as num?)?.toInt() ?? 1;
      cartNotifier.addToCart(food, quantity: qty);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Items added to your cart!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push(AppRoutes.cart);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not reorder: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

final orderCheckoutControllerProvider =
    StateNotifierProvider<OrderCheckoutNotifier, AsyncValue<OrderModel?>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderCheckoutNotifier(repository: repository, ref: ref);
});

class OrderCheckoutNotifier extends StateNotifier<AsyncValue<OrderModel?>> {
  final IOrderRepository repository;
  final Ref ref;

  OrderCheckoutNotifier({
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  Future<OrderModel?> placeOrder({
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final user = ref.read(currentUserProvider);
    final items = ref.read(cartProvider);
    final subtotal = ref.read(cartSubtotalProvider);
    final deliveryFee = ref.read(cartDeliveryFeeProvider);
    final tax = ref.read(cartTaxProvider);
    final total = ref.read(cartTotalProvider);

    if (user == null || items.isEmpty) return null;

    state = const AsyncValue.loading();
    try {
      final order = await repository.createOrder(
        userId: user.id,
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        tax: tax,
        total: total,
      );

      // For COD orders, start live delivery progression immediately
      if (paymentMethod == 'cod') {
        repository.startDeliverySimulation(order.id);
      }

      ref.read(cartProvider.notifier).clearCart();
      ref.invalidate(userOrdersProvider);

      state = AsyncValue.data(order);
      return order;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}
