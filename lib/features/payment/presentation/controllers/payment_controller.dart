import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_state_provider.dart';
import '../../../order/presentation/controllers/order_providers.dart';
import '../../data/models/payment_intent_result.dart';
import '../../data/payment_repository.dart';

class SavedCardInfo {
  final String brand;
  final String last4;
  final String holderName;
  final String expiry;

  const SavedCardInfo({
    this.brand = 'Mastercard',
    this.last4 = '4242',
    this.holderName = 'Hamza Khan',
    this.expiry = '08/27',
  });
}

/// Global user preference for payment method ('card', 'cod', or 'wallet')
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'card');

/// Selected wallet when 'wallet' is chosen ('JazzCash', 'Easypaisa', 'Apple Pay')
final selectedDigitalWalletProvider = StateProvider<String>((ref) => 'JazzCash');

/// Tactile saved card display info shown across Payment Method & Checkout
final savedCardInfoProvider =
    StateProvider<SavedCardInfo>((ref) => const SavedCardInfo());

final paymentRepositoryProvider = Provider<IPaymentRepository>((ref) {
  return StripePaymentRepository();
});

enum PaymentProcessingStatus {
  initial,
  loadingIntent,
  readyForCard,
  confirmingWithStripe,
  waitingForWebhook,
  success,
  error,
}

class PaymentState {
  final PaymentProcessingStatus status;
  final PaymentIntentResult? intentResult;
  final String? errorMessage;

  const PaymentState({
    this.status = PaymentProcessingStatus.initial,
    this.intentResult,
    this.errorMessage,
  });

  PaymentState copyWith({
    PaymentProcessingStatus? status,
    PaymentIntentResult? intentResult,
    String? errorMessage,
  }) {
    return PaymentState(
      status: status ?? this.status,
      intentResult: intentResult ?? this.intentResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final paymentControllerProvider =
    StateNotifierProvider.autoDispose<PaymentController, PaymentState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentController(repository: repository, ref: ref);
});

class PaymentController extends StateNotifier<PaymentState> {
  final IPaymentRepository repository;
  final Ref ref;

  PaymentController({
    required this.repository,
    required this.ref,
  }) : super(const PaymentState());

  /// Step 1: Request PaymentIntent from secure backend
  Future<bool> initializePayment({
    required String orderId,
    required double amount,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(
        status: PaymentProcessingStatus.error,
        errorMessage: 'User session expired. Please log in again.',
      );
      return false;
    }

    state = state.copyWith(status: PaymentProcessingStatus.loadingIntent);

    try {
      final result = await repository.createPaymentIntent(
        orderId: orderId,
        userId: user.id,
        amount: amount,
        customerEmail: user.email,
      );

      state = state.copyWith(
        status: PaymentProcessingStatus.readyForCard,
        intentResult: result,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: PaymentProcessingStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Step 2: Confirm card with Stripe and wait for synchronization
  Future<bool> confirmPayment({
    required String orderId,
  }) async {
    state = state.copyWith(status: PaymentProcessingStatus.confirmingWithStripe);

    final intentId = state.intentResult?.paymentIntentId;
    if (intentId != null && intentId.isNotEmpty) {
      final confirmed = await repository.confirmPaymentIntent(
        paymentIntentId: intentId,
        orderId: orderId,
      );
      if (!confirmed) {
        state = state.copyWith(
          status: PaymentProcessingStatus.error,
          errorMessage: 'Card payment confirmation failed. Please check backend & try again.',
        );
        return false;
      }
    }

    state = state.copyWith(status: PaymentProcessingStatus.waitingForWebhook);

    try {
      final verified = await repository.waitForPaymentVerification(
        orderId,
        timeout: const Duration(seconds: 10),
      );

      ref.invalidate(userOrdersProvider);
      if (!verified) {
        state = state.copyWith(
          status: PaymentProcessingStatus.error,
          errorMessage: 'Payment is awaiting webhook verification. Check Order History in a moment.',
        );
        return false;
      }

      state = state.copyWith(status: PaymentProcessingStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: PaymentProcessingStatus.error,
        errorMessage: 'Payment verification error: $e',
      );
      return false;
    }
  }
}

