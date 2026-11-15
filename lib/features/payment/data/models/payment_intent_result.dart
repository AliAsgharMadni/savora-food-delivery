class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final int amount;
  final String currency;
  final bool isSimulated;

  const PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.isSimulated,
  });

  factory PaymentIntentResult.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResult(
      clientSecret: json['clientSecret'] as String,
      paymentIntentId: json['paymentIntentId'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: (json['currency'] as String?) ?? 'usd',
      isSimulated: (json['isSimulated'] as bool?) ?? false,
    );
  }
}

