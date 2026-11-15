import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }

    if (Env.isConfigured) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: Env.supabaseAnonKey,
      );
    } else {
      debugPrint(
        'Supabase is not configured yet. Please update .env with your SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }

  static SupabaseClient? get client {
    if (Env.isConfigured) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
