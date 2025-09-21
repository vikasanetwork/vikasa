import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    // Try load .env asset (non-fatal if missing)
    try {
      await dotenv.load(fileName: 'assets/env/.env');
    } catch (_) {}

    final url = dotenv.maybeGet('SUPABASE_URL');
    final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY');

    if (url != null && url.isNotEmpty && anonKey != null && anonKey.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _initialized = true;
    } else {
      // Not configured yet; app can still run without Supabase in dev
      _initialized = false;
    }
  }
}
