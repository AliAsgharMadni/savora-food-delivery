import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get backendUrl {
    final raw = dotenv.get('BACKEND_URL', fallback: 'http://localhost:3000').trim();
    final sanitized = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    // On Android emulators, 10.0.2.2 connects to host machine's localhost
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && sanitized.contains('localhost')) {
      return sanitized.replaceAll('localhost', '10.0.2.2');
    }
    return sanitized;
  }

  static String get stripePublishableKey =>
      dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: 'pk_test_placeholder');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id');

  static bool get isStripeConfigured =>
      stripePublishableKey.isNotEmpty &&
      !stripePublishableKey.contains('placeholder');
}
