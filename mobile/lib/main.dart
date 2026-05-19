import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NoorAIApp());
}

class NoorAIApp extends StatelessWidget {
  const NoorAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoorAI',
      debugShowCheckedModeBanner: false,
      theme: buildNoorTheme(),
      home: const SplashScreen(),
    );
  }
}
