class AppRoutes {
  const AppRoutes._();

  // Onboarding (public)
  static const String onboarding = '/onboarding';

  // Auth routes (public / guest only)
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Protected routes (requires authentication)
  static const String home = '/';
  static const String profile = '/profile';
  static const String foodDetail = '/food-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String paymentMethod = '/payment-method';
  static const String stripePayment = '/stripe-payment';
  static const String paymentSuccess = '/payment-success';
  static const String orderTracking = '/order-tracking';
  static const String orderHistory = '/order-history';
  static const String orderDetail = '/order-detail';
  static const String savedAddresses = '/saved-addresses';
  static const String emptyStates = '/empty-states';

  static const List<String> authRoutes = [
    onboarding,
    login,
    signup,
    forgotPassword,
  ];

  static bool isAuthRoute(String path) {
    return authRoutes.contains(path);
  }
}
