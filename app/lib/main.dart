import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/main_layout.dart';
import 'data/user_repository.dart';
import 'engine/safety/safety_rules_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepo = UserRepository();
  final profile = await userRepo.loadProfile();

  // Open directly into main practice layout without initial health screening blocker
  final home = MainLayout(safetyProfile: profile ?? SafetyProfile());

  runApp(AbhyasApp(home: home));
}

class AbhyasApp extends StatelessWidget {
  final Widget home;

  const AbhyasApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PranaFlow',
      debugShowCheckedModeBanner: false,
      theme: AbhyasTheme.darkTheme,
      home: home,
    );
  }
}
