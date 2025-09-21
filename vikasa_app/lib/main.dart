import 'package:flutter/material.dart';
import 'app/vikasa_app.dart';
import 'firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  runApp(const VikasaApp());
}
