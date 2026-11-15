import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/errors/failure.dart';
import 'models/payment_intent_result.dart';

abstract class IPaymentRepository {
  /// Calls the secure backend server to generate a Stripe PaymentIntent
  Future<PaymentIntentResult> createPaymentIntent({
    required String orderId,
    required String userId,
    required double amount,
    String? customerEmail,
  });

  /// Confirms a Stripe PaymentIntent via the secure backend
  Future<bool> confirmPaymentIntent({
    required String paymentIntentId,
    required String orderId,
    String paymentMethodId = 'pm_card_visa',
  });

  /// Synchronizes and awaits payment status from Supabase (updated solely by Stripe Webhook)
  Future<bool> waitForPaymentVerification(String orderId, {Duration timeout = const Duration(seconds: 30)});
}

class StripePaymentRepository implements IPaymentRepository {
  final http.Client httpClient;
  final SupabaseClient? supabaseClient;

  StripePaymentRepository({
    http.Client? httpClient,
    this.supabaseClient,
  }) : httpClient = httpClient ?? http.Client();

  SupabaseClient get _safeSupabase =>
      supabaseClient ?? Supabase.instance.client;

  @override
  Future<PaymentIntentResult> createPaymentIntent({
    required String orderId,
    required String userId,
    required double amount,
    String? customerEmail,
  }) async {
    try {
      final url = Uri.parse('${Env.backendUrl}/api/create-payment-intent');
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'userId': userId,
          'amount': amount,
          'currency': 'usd',
          'customerEmail': customerEmail,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaymentIntentResult.fromJson(data);
      } else {
        final errorBody = response.body;
        throw Failure('Backend PaymentIntent creation failed: $errorBody');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure('Could not connect to payment backend at ${Env.backendUrl}: $e');
    }
  }

  @override
  Future<bool> confirmPaymentIntent({
    required String paymentIntentId,
    required String orderId,
    String paymentMethodId = 'pm_card_visa',
  }) async {
    try {
      final url = Uri.parse('${Env.backendUrl}/api/confirm-payment-intent');
      final response = await httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'orderId': orderId,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> waitForPaymentVerification(
    String orderId, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    Future<bool> isOrderPaid() async {
      try {
        final data = await _safeSupabase
            .from('orders')
            .select('payment_status')
            .eq('id', orderId)
            .maybeSingle();
        return data != null && data['payment_status'] == 'paid';
      } catch (_) {
        return false;
      }
    }

    // Immediate check first so server-confirmed orders return instantly
    if (await isOrderPaid()) return true;

    final completer = Completer<bool>();
    final deadline = DateTime.now().add(timeout);

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (DateTime.now().isAfter(deadline)) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(false);
        return;
      }

      if (await isOrderPaid()) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    return completer.future;
  }
}
