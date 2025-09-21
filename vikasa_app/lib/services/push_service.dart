import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

    // TODO: send token to Supabase (push_tokens table) after we add table + auth session
    // For now, just log to console
    if (token != null) {
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
