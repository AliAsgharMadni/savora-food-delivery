import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/controllers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/addresses/presentation/screens/saved_addresses_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/food/data/models/food_item.dart';
import '../../features/food/presentation/screens/food_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/order/data/models/order.dart';
import '../../features/order/presentation/screens/checkout_screen.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/order/presentation/screens/order_history_screen.dart';
import '../../features/order/presentation/screens/order_tracking_screen.dart';
import '../../features/order/presentation/screens/payment_success_screen.dart';
import '../../features/payment/presentation/screens/payment_method_screen.dart';
import '../../features/payment/presentation/screens/stripe_payment_sheet_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../utils/router_refresh_stream.dart';
import '../widgets/empty_states_screen.dart';
import 'route_names.dart';

const _kOnboardingKey = 'has_seen_onboarding';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (BuildContext context, GoRouterState state) async {
      final session = authRepository.currentSession;
      final user = authRepository.currentUser;
      final isAuthenticated = session != null || user != null;

      final matchedLocation = state.matchedLocation;
      final isAuthRoute = AppRoutes.isAuthRoute(matchedLocation);

      // Check onboarding: only show once for unauthenticated users
      if (matchedLocation == AppRoutes.home && !isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getBool(_kOnboardingKey) ?? false;
        if (!seen) return AppRoutes.onboarding;
        return AppRoutes.login;
      }

      // Unauthenticated user trying to access protected route -> Login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Authenticated user trying to access login/signup/forgotPassword -> Home
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Protected routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodDetail,
        builder: (context, state) {
          final food = state.extra;
          if (food is! FoodItem) return const HomeScreen();
          return FoodDetailScreen(food: food);
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: AppRoutes.stripePayment,
        builder: (context, state) {
          final order = state.extra;
          if (order is! OrderModel) return const OrderHistoryScreen();
          return StripePaymentSheetScreen(order: order);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) {
          final order = state.extra;
          if (order is! OrderModel) return const OrderHistoryScreen();
          return PaymentSuccessScreen(order: order);
        },
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        builder: (context, state) {
          final orderId = state.extra;
          if (orderId is! String || orderId.isEmpty) {
            return const OrderHistoryScreen();
          }
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.orderHistory,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final order = state.extra;
          if (order is! OrderModel) return const OrderHistoryScreen();
          return OrderDetailScreen(order: order);
        },
      ),
      GoRoute(
        path: AppRoutes.savedAddresses,
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.emptyStates,
        builder: (context, state) => const EmptyStatesScreen(),
      ),
    ],
  );
});
