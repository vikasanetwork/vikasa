import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (Android/iOS). Keep minimal.
}

class PushService {
  PushService._();
  static final instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Background handler registration (mobile)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    // Permissions (iOS / Android 13+ runtime prompt)
    await _messaging.requestPermission();

    // Get FCM token
    final token = await _messaging.getToken();

    // Upload token to Supabase if logged in and client initialized
    if (token != null) {
      try {
        final supa = Supabase.maybeGetInstance();
        final user = supa?.client.auth.currentUser;
        if (supa != null && user != null) {
          final platform = kIsWeb ? 'web' : 'mobile';
          await supa.client.from('push_tokens').upsert({
            'user_id': user.id,
            'token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,token,platform');
        }
      } catch (_) {
        // ignore; token upload is best-effort
      }
      // ignore: avoid_print
      print('FCM token: ' + token);
    }

    // Foreground message listener (optional placeholder)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ignore: avoid_print
      print('FCM foreground: ' + (message.notification?.title ?? '')); 
    });
  }
}
