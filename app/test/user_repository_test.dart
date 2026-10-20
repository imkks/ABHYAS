import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abhyas/data/user_repository.dart';
import 'package:abhyas/engine/safety/safety_rules_engine.dart';

void main() {
  group('UserRepository', () {
    late UserRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = UserRepository();
    });

    test('saveProfile and loadProfile round-trip preserves all flags', () async {
      final profile = SafetyProfile(
        pregnancy: true,
        hypertension: false,
        heartCondition: true,
        epilepsy: false,
        glaucoma: true,
        hernia: false,
        recentSurgery: true,
        menstruation: true,
        emptyStomachConfirmed: true,
      );

      await repo.saveProfile(profile);
      final loaded = await repo.loadProfile();

      expect(loaded, isNotNull);
      expect(loaded!.pregnancy, true);
      expect(loaded.hypertension, false);
      expect(loaded.heartCondition, true);
      expect(loaded.epilepsy, false);
      expect(loaded.glaucoma, true);
      expect(loaded.hernia, false);
      expect(loaded.recentSurgery, true);
      expect(loaded.menstruation, true);
      expect(loaded.emptyStomachConfirmed, true);
    });

    test('loadProfile returns null when no profile has been saved', () async {
      final loaded = await repo.loadProfile();
      expect(loaded, isNull);
    });

    test('saveTradition and loadTradition round-trip', () async {
      await repo.saveTradition('Shaiva');
      final tradition = await repo.loadTradition();
      expect(tradition, 'Shaiva');
    });

    test('loadTradition returns null when nothing saved', () async {
      final tradition = await repo.loadTradition();
      expect(tradition, isNull);
    });

    test('saveConsent and hasCompletedOnboarding round-trip', () async {
      await repo.saveConsent(true);
      final completed = await repo.hasCompletedOnboarding();
      expect(completed, true);
    });

    test('hasCompletedOnboarding returns false initially', () async {
      final completed = await repo.hasCompletedOnboarding();
      expect(completed, false);
    });

    test('saveChtBenchmark and loadChtBenchmark round-trip', () async {
      await repo.saveChtBenchmark(12.5);
      final value = await repo.loadChtBenchmark();
      expect(value, 12.5);
    });

    test('loadChtBenchmark returns null when nothing saved', () async {
      final value = await repo.loadChtBenchmark();
      expect(value, isNull);
    });
  });
}
