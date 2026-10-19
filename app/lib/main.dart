import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  runApp(AbhyasApp());
}

class AbhyasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abhyas',
      debugShowCheckedModeBanner: false,
      theme: AbhyasTheme.darkTheme,
      home: OnboardingScreen(),
    );
  }
}
