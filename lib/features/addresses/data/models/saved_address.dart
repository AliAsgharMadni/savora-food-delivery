class SavedAddress {
  final String id;
  final String userId;
  final String title;
  final String street;
  final String city;
  final String? state;
  final String? postalCode;
  final bool isDefault;
  final DateTime createdAt;

  const SavedAddress({
    required this.id,
    required this.userId,
    required this.title,
    required this.street,
    required this.city,
    this.state,
    this.postalCode,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] as String?) ?? 'Home',
      street: (json['street'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get formattedAddress {
    final parts = <String>[
      if (street.trim().isNotEmpty) street.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (state != null && state!.trim().isNotEmpty) state!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty)
        postalCode!.trim(),
    ];
    return parts.join(', ');
  }
}

