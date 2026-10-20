import 'package:shared_preferences/shared_preferences.dart';
import '../engine/safety/safety_rules_engine.dart';

/// Persists user-level data: SafetyProfile, Sampradaya tradition,
/// onboarding consent, and CHT benchmark value.
class UserRepository {
  static const String _keyPregnancy = 'profile_pregnancy';
  static const String _keyHypertension = 'profile_hypertension';
  static const String _keyHeartCondition = 'profile_heartCondition';
  static const String _keyEpilepsy = 'profile_epilepsy';
  static const String _keyGlaucoma = 'profile_glaucoma';
  static const String _keyHernia = 'profile_hernia';
  static const String _keyRecentSurgery = 'profile_recentSurgery';
  static const String _keyMenstruation = 'profile_menstruation';
  static const String _keyEmptyStomach = 'profile_emptyStomachConfirmed';
  static const String _keyProfileSaved = 'profile_saved';
  static const String _keyTradition = 'user_tradition';
  static const String _keyConsent = 'user_consent';
  static const String _keyChtBenchmark = 'user_cht_benchmark';

  Future<void> saveProfile(SafetyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPregnancy, profile.pregnancy);
    await prefs.setBool(_keyHypertension, profile.hypertension);
    await prefs.setBool(_keyHeartCondition, profile.heartCondition);
    await prefs.setBool(_keyEpilepsy, profile.epilepsy);
    await prefs.setBool(_keyGlaucoma, profile.glaucoma);
    await prefs.setBool(_keyHernia, profile.hernia);
    await prefs.setBool(_keyRecentSurgery, profile.recentSurgery);
    await prefs.setBool(_keyMenstruation, profile.menstruation);
    await prefs.setBool(_keyEmptyStomach, profile.emptyStomachConfirmed);
    await prefs.setBool(_keyProfileSaved, true);
  }

  Future<SafetyProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyProfileSaved) ?? false)) {
      return null;
    }
    return SafetyProfile(
      pregnancy: prefs.getBool(_keyPregnancy) ?? false,
      hypertension: prefs.getBool(_keyHypertension) ?? false,
      heartCondition: prefs.getBool(_keyHeartCondition) ?? false,
      epilepsy: prefs.getBool(_keyEpilepsy) ?? false,
      glaucoma: prefs.getBool(_keyGlaucoma) ?? false,
      hernia: prefs.getBool(_keyHernia) ?? false,
      recentSurgery: prefs.getBool(_keyRecentSurgery) ?? false,
      menstruation: prefs.getBool(_keyMenstruation) ?? false,
      emptyStomachConfirmed: prefs.getBool(_keyEmptyStomach) ?? false,
    );
  }

  Future<void> saveTradition(String tradition) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTradition, tradition);
  }

  Future<String?> loadTradition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTradition);
  }

  Future<void> saveConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsent, consent);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyConsent) ?? false;
  }

  Future<void> saveChtBenchmark(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyChtBenchmark, value);
  }

  Future<double?> loadChtBenchmark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyChtBenchmark);
  }
}
