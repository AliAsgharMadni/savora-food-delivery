import '../../../food/data/models/food_item.dart';

class CartItem {
  final FoodItem food;
  final int quantity;

  const CartItem({
    required this.food,
    this.quantity = 1,
  });

  double get totalPrice => food.price * quantity;

  CartItem copyWith({
    FoodItem? food,
    int? quantity,
  }) {
    return CartItem(
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
    );
  }
}

