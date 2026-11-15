import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../order/data/models/order.dart';
import '../controllers/payment_controller.dart';

class StripePaymentSheetScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const StripePaymentSheetScreen({super.key, required this.order});

  @override
  ConsumerState<StripePaymentSheetScreen> createState() =>
      _StripePaymentSheetScreenState();
}

class _StripePaymentSheetScreenState
    extends ConsumerState<StripePaymentSheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController =
      TextEditingController(text: '4242 •••• •••• 4242');
  final _expiryController = TextEditingController(text: '12/28');
  final _cvcController = TextEditingController(text: '888');
  final _zipController = TextEditingController(text: '90210');

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(paymentControllerProvider.notifier);

    // 1. Request secure PaymentIntent from server
    final initOk = await controller.initializePayment(
      orderId: widget.order.id,
      amount: widget.order.total,
    );

    if (!initOk && mounted) {
      final err = ref.read(paymentControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Could not initialize Stripe intent.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. Process with Stripe & wait for Webhook synchronization
    final success = await controller.confirmPayment(orderId: widget.order.id);

    if (!mounted) return;
    if (success) {
      context.go(
        AppRoutes.paymentSuccess,
        extra: widget.order,
      );
    } else {
      final err = ref.read(paymentControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Payment could not be confirmed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final paymentState = ref.watch(paymentControllerProvider);
    final isLoading =
        paymentState.status == PaymentProcessingStatus.loadingIntent ||
        paymentState.status == PaymentProcessingStatus.waitingForWebhook ||
        paymentState.status == PaymentProcessingStatus.confirmingWithStripe;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Stripe Card Payment',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stripe Secure Gateway Badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF635BFF).withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF635BFF).withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFF635BFF), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stripe End-to-End Encryption',
                            style: TextStyle(
                              color: Color(0xFF635BFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'PaymentIntents generated server-side. Card credentials never touch app servers.',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Order Summary Mini
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to Authorize',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card Input Form
              const Text(
                'Card Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        hintText: '4242 4242 4242 4242',
                        prefixIcon: Icon(Icons.credit_card, color: AppColors.primary),
                        border: InputBorder.none,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter a valid card number';
                        }
                        return null;
                      },
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.datetime,
                            decoration: const InputDecoration(
                              labelText: 'Expires (MM/YY)',
                              hintText: '12/28',
                              border: InputBorder.none,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _cvcController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'CVC',
                              hintText: '123',
                              border: InputBorder.none,
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Billing ZIP Code',
                        hintText: '90210',
                        border: InputBorder.none,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Pay Now CTA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  onPressed: isLoading ? null : _processPayment,
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              paymentState.status ==
                                      PaymentProcessingStatus.waitingForWebhook
                                  ? 'Awaiting Webhook Confirmation...'
                                  : 'Contacting Stripe...',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : Text(
                          'Pay \$${order.total.toStringAsFixed(2)} with Stripe',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

