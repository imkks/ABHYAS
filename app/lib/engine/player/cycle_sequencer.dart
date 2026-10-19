import 'dart:async';

/// Represents a single practice step within a sequenced Sadhana cycle.
class CycleStepItem {
  final String id;
  final String title;
  final String subtitle;
  final int durationSeconds;
  final List<int>? ratio; // [puraka, antar, rechaka, bahya]
  final bool isRequired;
  final bool isPranayamaWithPacer;

  CycleStepItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationSeconds,
    this.ratio,
    this.isRequired = false,
    this.isPranayamaWithPacer = false,
  });
}

/// Pure Dart state machine orchestrating sequential execution of a practice cycle.
class CycleSequencer {
  final List<CycleStepItem> steps;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  int _currentStepIndex = 0;
  int _secondsInCurrentStep = 0;
  int _totalSecondsElapsed = 0;
  bool _isPaused = false;
  bool _isCompleted = false;

  void Function(int stepIndex, int stepSeconds, int totalSeconds)? _onTick;
  void Function(int completedStepIndex)? _onStepComplete;
  void Function()? _onCycleComplete;

  CycleSequencer({required this.steps}) : assert(steps.isNotEmpty);

  int get currentStepIndex => _currentStepIndex;
  int get secondsInCurrentStep => _secondsInCurrentStep;
  int get totalSecondsElapsed => _totalSecondsElapsed;
  bool get isRunning => _stopwatch.isRunning;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;

  CycleStepItem get currentStep => steps[_currentStepIndex];

  int get totalCycleDurationSeconds =>
      steps.fold(0, (sum, step) => sum + step.durationSeconds);

  double get overallProgress => totalCycleDurationSeconds > 0
      ? (_totalSecondsElapsed / totalCycleDurationSeconds).clamp(0.0, 1.0)
      : 0.0;

  double get currentStepProgress => currentStep.durationSeconds > 0
      ? (_secondsInCurrentStep / currentStep.durationSeconds).clamp(0.0, 1.0)
      : 0.0;

  void start({
    void Function(int stepIndex, int stepSeconds, int totalSeconds)? onTick,
    void Function(int completedStepIndex)? onStepComplete,
    void Function()? onCycleComplete,
  }) {
    _onTick = onTick;
    _onStepComplete = onStepComplete;
    _onCycleComplete = onCycleComplete;

    _currentStepIndex = 0;
    _secondsInCurrentStep = 0;
    _totalSecondsElapsed = 0;
    _isPaused = false;
    _isCompleted = false;

    _stopwatch.reset();
    _stopwatch.start();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_stopwatch.isRunning) return;

      _secondsInCurrentStep++;
      _totalSecondsElapsed++;

      _onTick?.call(_currentStepIndex, _secondsInCurrentStep, _totalSecondsElapsed);

      if (_secondsInCurrentStep >= currentStep.durationSeconds) {
        _advanceToNextStep();
      }
    });
  }

  void _advanceToNextStep() {
    _onStepComplete?.call(_currentStepIndex);

    if (_currentStepIndex + 1 < steps.length) {
      _currentStepIndex++;
      _secondsInCurrentStep = 0;
      _onTick?.call(_currentStepIndex, _secondsInCurrentStep, _totalSecondsElapsed);
    } else {
      _completeCycle();
    }
  }

  void skipStep() {
    if (_isCompleted) return;
    _advanceToNextStep();
  }

  void pause() {
    _stopwatch.stop();
    _isPaused = true;
  }

  void resume() {
    if (_isCompleted) return;
    _stopwatch.start();
    _isPaused = false;
  }

  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
  }

  void _completeCycle() {
    stop();
    _isCompleted = true;
    _onCycleComplete?.call();
  }
}
