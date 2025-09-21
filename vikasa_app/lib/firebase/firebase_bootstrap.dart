import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import '../services/push_service.dart';

Future<void> bootstrapFirebase() async {
  try {
    // Initialize with generated options (placeholder values until FlutterFire config is added).
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // As a fallback for non-web, try default initialization (if native files exist).
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        // ignore; app can still run without Firebase in dev
      }
    }
  }

  // Configure Messaging if available on this platform
  if (!kIsWeb || (kIsWeb && DefaultFirebaseOptions.webConfigured)) {
    await PushService.instance.init();
  }
}
