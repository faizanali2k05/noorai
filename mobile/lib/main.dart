import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const NoorAIApp());
}

class NoorAIApp extends StatelessWidget {
  const NoorAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoorAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
        useMaterial3: true,
        fontFamily: 'Inter', // Note: Need to add font to pubspec to truly show this, defaulting to system for now
      ),
      home: const HomeScreen(),
    );
  }
}
