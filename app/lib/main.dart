import 'package:flutter/material.dart';
import 'data/local_storage_service.dart';
import 'data/supabase_service.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mocking local storage init since it doesn't have an init method currently.
  // await LocalStorageService.init();
  await SupabaseService.initialize();
  runApp(const AbhyasApp());
}

class AbhyasApp extends StatelessWidget {
  const AbhyasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abhyas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
