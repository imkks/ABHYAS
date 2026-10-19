class WeaningLadder {
  int currentStage = 1;

  String getStageDescription() {
    switch (currentStage) {
      case 1: return 'Guided (Full voice & visual)';
      case 2: return 'Cued (Phase changes only)';
      case 3: return 'Silent Timer (Haptic pulses)';
      case 4: return 'Self-led (Start/End bells only)';
      case 5: return 'Independent (Self-check)';
      default: return 'Unknown';
    }
  }

  void advanceStage() {
    if (currentStage < 5) {
      currentStage++;
    }
  }
}
