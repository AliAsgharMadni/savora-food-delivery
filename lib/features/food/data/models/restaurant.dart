class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final String deliveryTime;
  final double deliveryFee;
  final String category;
  final bool isFeatured;
  final String? address;

  const Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.category,
    required this.isFeatured,
    this.address,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?) ?? '',
      rating: ((json['rating'] as num?) ?? 4.8).toDouble(),
      deliveryTime: (json['delivery_time'] as String?) ?? '20-30 min',
      deliveryFee: ((json['delivery_fee'] as num?) ?? 2.99).toDouble(),
      category: (json['category'] as String?) ?? 'General',
      isFeatured: (json['is_featured'] as bool?) ?? false,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'delivery_time': deliveryTime,
      'delivery_fee': deliveryFee,
      'category': category,
      'is_featured': isFeatured,
      'address': address,
    };
  }
}

