import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';

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
      home: const LoginScreen(),
    );
  }
}
