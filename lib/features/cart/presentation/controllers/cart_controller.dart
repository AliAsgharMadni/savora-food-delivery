import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item.dart';
import '../../../food/data/models/food_item.dart';

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(FoodItem food, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.food.id == food.id);
    if (existingIndex >= 0) {
      final currentItem = state[existingIndex];
      final updatedList = List<CartItem>.from(state);
      updatedList[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + quantity,
      );
      state = updatedList;
    } else {
      state = [...state, CartItem(food: food, quantity: quantity)];
    }
  }

  void updateQuantity(String foodId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(foodId);
      return;
    }

    state = state.map((item) {
      if (item.food.id == foodId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void removeFromCart(String foodId) {
    state = state.where((item) => item.food.id != foodId).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalPrice);
});

final cartDeliveryFeeProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.isEmpty ? 0.0 : 2.99;
});

final cartPromoCodeProvider = StateProvider<String?>((ref) => 'SAVORA20');

final cartDiscountProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final promo = ref.watch(cartPromoCodeProvider)?.trim().toUpperCase();
  if (subtotal <= 0 || promo == null || promo.isEmpty) return 0.0;
  if (promo == 'SAVORA20') {
    return double.parse((subtotal * 0.20).toStringAsFixed(2));
  }
  return 0.0;
});

final cartTaxProvider = Provider<double>((ref) {
  // Prices are inclusive of local taxes
  return 0.0;
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final fee = ref.watch(cartDeliveryFeeProvider);
  final tax = ref.watch(cartTaxProvider);
  final discount = ref.watch(cartDiscountProvider);
  final computed = subtotal + fee + tax - discount;
  return computed > 0 ? double.parse(computed.toStringAsFixed(2)) : 0.0;
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

