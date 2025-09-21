import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../features/claim/claim_page.dart';

class VikasaApp extends StatelessWidget {
  const VikasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIKASA',
      debugShowCheckedModeBanner: false,
      theme: buildVikasaTheme(),
      home: const ClaimPage(),
    );
  }
}
