class OrderModel {
  final String id;
  final String userId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: (json['status'] as String?) ?? 'pending',
      subtotal: ((json['subtotal'] as num?) ?? 0.0).toDouble(),
      deliveryFee: ((json['delivery_fee'] as num?) ?? 2.99).toDouble(),
      tax: ((json['tax'] as num?) ?? 1.50).toDouble(),
      total: ((json['total'] as num?) ?? 0.0).toDouble(),
      deliveryAddress: (json['delivery_address'] as String?) ?? 'Default Address',
      paymentMethod: (json['payment_method'] as String?) ?? 'card',
      paymentStatus: (json['payment_status'] as String?) ?? 'unpaid',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total': total,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
    };
  }
}

class OrderEvent {
  final String id;
  final String orderId;
  final String status;
  final String title;
  final String? description;
  final DateTime createdAt;

  const OrderEvent({
    required this.id,
    required this.orderId,
    required this.status,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

