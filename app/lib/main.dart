import 'package:flutter/material.dart';
import 'ui/onboarding_screen.dart';

void main() {
  runApp(AbhyasApp());
}

class AbhyasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abhyas Phase 1 E2E',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OnboardingScreen(),
    );
  }
}
