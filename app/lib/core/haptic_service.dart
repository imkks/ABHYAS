import 'package:haptic_feedback/haptic_feedback.dart';

/// Centralized haptic feedback controller calibrated to weaning stages (1–5).
/// Disabled by default so that constant ticking does not disturb practice or muddy modes.
class HapticService {
  // Singleton pattern
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Whether haptic feedback is globally enabled.
  /// Kept false by default to prevent continuous buzzing/ticking during breathwork.
  bool isEnabled = false;

  /// Called on each matra (beat) tick during practice.
  void pulseForMatra(int weaningStage) {
    if (!isEnabled) return;
    if (weaningStage <= 2) {
      Haptics.vibrate(HapticsType.light);
    }
  }

  /// Called on each breath phase transition (puraka → kumbhaka → rechaka, etc.).
  void phaseTransitionPulse(int weaningStage) {
    if (!isEnabled) return;
    if (weaningStage <= 3) {
      Haptics.vibrate(HapticsType.medium);
    } else if (weaningStage == 4) {
      Haptics.vibrate(HapticsType.light);
    }
  }

  /// Called at the end of each practice round.
  void roundCompletePulse(int weaningStage) {
    if (!isEnabled) return;
    if (weaningStage <= 4) {
      Haptics.vibrate(HapticsType.heavy);
    }
  }

  /// Called when the entire practice session is complete.
  void completionPulse() {
    if (!isEnabled) return;
    Haptics.vibrate(HapticsType.heavy);
  }
}
