import 'dart:async';

class YogaNidraPlayer {
  final int durationMinutes;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  YogaNidraPlayer({required this.durationMinutes});

  void start(Function(int) onTick, Function onComplete) {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final elapsed = _stopwatch.elapsed.inSeconds;
      onTick(elapsed);

      if (elapsed >= (durationMinutes * 60)) {
         stop();
         onComplete();
      }
    });
  }

  void pause() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void stop() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
  }
}
