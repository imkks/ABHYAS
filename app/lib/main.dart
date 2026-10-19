import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/main_layout.dart';
import 'data/user_repository.dart';
import 'engine/safety/safety_rules_engine.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepo = UserRepository();
  final hasOnboarded = await userRepo.hasCompletedOnboarding();

  Widget home;
  if (hasOnboarded) {
    final profile = await userRepo.loadProfile();
    home = MainLayout(safetyProfile: profile ?? SafetyProfile());
  } else {
    home = OnboardingScreen();
  }

  runApp(AbhyasApp(home: home));
}

class AbhyasApp extends StatelessWidget {
  final Widget home;

  const AbhyasApp({Key? key, required this.home}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abhyas',
      debugShowCheckedModeBanner: false,
      theme: AbhyasTheme.darkTheme,
      home: home,
    );
  }
}
