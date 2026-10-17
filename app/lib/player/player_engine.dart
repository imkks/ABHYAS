import 'dart:math';
import 'dart:async';

enum PracticePhase {
  puraka,
  antarKumbhaka,
  rechaka,
  bahyaKumbhaka,
  naturalBreath
}

class PlayerEngine {
  final double holdCapFractionOfCht;
  final int levelCapSeconds;
  final int userChtSeconds;

  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  PlayerEngine({
    required this.holdCapFractionOfCht,
    required this.levelCapSeconds,
    required this.userChtSeconds,
  });

  void startTimer(Function(int) onTick) {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      onTick(_stopwatch.elapsed.inSeconds);
    });
  }

  void stopTimer() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
  }

  /// AC-2: Hold capped by min(level_cap, user_CHT × cap_fraction)
  int calculateMaxHoldSeconds() {
    double userCap = userChtSeconds * holdCapFractionOfCht;
    return min(levelCapSeconds.toDouble(), userCap).toInt();
  }

  /// Calculates actual scheduled hold based on ratio requirement,
  /// but firmly capped by calculateMaxHoldSeconds().
  int scheduleHold(int ratioRequiredSeconds) {
    int maxAllowed = calculateMaxHoldSeconds();
    return min(ratioRequiredSeconds, maxAllowed);
  }

  /// State transitions
  PracticePhase getNextPhase(PracticePhase current) {
    switch (current) {
      case PracticePhase.puraka:
        return PracticePhase.antarKumbhaka;
      case PracticePhase.antarKumbhaka:
        return PracticePhase.rechaka;
      case PracticePhase.rechaka:
        return PracticePhase.bahyaKumbhaka;
      case PracticePhase.bahyaKumbhaka:
        return PracticePhase.puraka;
      case PracticePhase.naturalBreath:
        return PracticePhase.puraka;
    }
  }

  /// AC-9: Stops immediately to natural breath
  PracticePhase returnToNaturalBreath() {
    return PracticePhase.naturalBreath;
  }
}
