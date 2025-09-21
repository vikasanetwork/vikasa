import 'package:flutter/material.dart';
import 'app/vikasa_app.dart';
import 'firebase/firebase_bootstrap.dart';
import 'supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  await bootstrapFirebase();
  runApp(const VikasaApp());
}
