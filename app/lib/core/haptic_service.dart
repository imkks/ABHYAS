import 'package:haptic_feedback/haptic_feedback.dart';

/// Centralized haptic feedback controller calibrated to weaning stages (1–5).
///
/// As the practitioner advances through weaning stages, haptic cues are
/// progressively reduced:
/// - Stages 1–2: Full haptic guidance (every beat + transitions + rounds)
/// - Stage 3: Transition and round cues only (no per-beat haptic)
/// - Stage 4: Light transitions and round cues only
/// - Stage 5: Only the final completion pulse (all other haptics silenced)
class HapticService {
  // Singleton pattern
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Called on each matra (beat) tick during practice.
  ///
  /// - Stages 1–2: Light haptic on every beat
  /// - Stages 3–5: No per-beat haptic
  void pulseForMatra(int weaningStage) {
    if (weaningStage <= 2) {
      Haptics.vibrate(HapticsType.light);
    }
    // Stages 3-5: no per-beat haptic
  }

  /// Called on each breath phase transition (puraka → kumbhaka → rechaka, etc.).
  ///
  /// - Stages 1–3: Medium haptic
  /// - Stage 4: Light haptic
  /// - Stage 5: No haptic
  void phaseTransitionPulse(int weaningStage) {
    if (weaningStage <= 3) {
      Haptics.vibrate(HapticsType.medium);
    } else if (weaningStage == 4) {
      Haptics.vibrate(HapticsType.light);
    }
    // Stage 5: no haptic
  }

  /// Called at the end of each practice round.
  ///
  /// - Stages 1–4: Heavy haptic
  /// - Stage 5: No haptic
  void roundCompletePulse(int weaningStage) {
    if (weaningStage <= 4) {
      Haptics.vibrate(HapticsType.heavy);
    }
    // Stage 5: no haptic
  }

  /// Called when the entire practice session is complete.
  ///
  /// Always fires a heavy haptic regardless of weaning stage.
  void completionPulse() {
    Haptics.vibrate(HapticsType.heavy);
  }
}
