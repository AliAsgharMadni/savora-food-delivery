class FoodItem {
  final String id;
  final String? restaurantId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int? calories;
  final String prepTime;
  final bool isPopular;

  const FoodItem({
    required this.id,
    this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    this.calories,
    required this.prepTime,
    required this.isPopular,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String?,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      price: ((json['price'] as num?) ?? 0.0).toDouble(),
      imageUrl: (json['image_url'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'General',
      rating: ((json['rating'] as num?) ?? 4.9).toDouble(),
      calories: json['calories'] as int?,
      prepTime: (json['prep_time'] as String?) ?? '15-20 min',
      isPopular: (json['is_popular'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'rating': rating,
      'calories': calories,
      'prep_time': prepTime,
      'is_popular': isPopular,
    };
  }
}

