import 'package:flutter_test/flutter_test.dart';
import 'package:abhyas/engine/player/cycle_sequencer.dart';

void main() {
  group('CycleSequencer', () {
    test('initializes with steps and calculates total duration', () {
      final steps = [
        CycleStepItem(id: 'sankalp', title: 'Sankalp', subtitle: '', durationSeconds: 60),
        CycleStepItem(id: 'pranayama', title: 'Pranayama', subtitle: '', durationSeconds: 120),
      ];

      final sequencer = CycleSequencer(steps: steps);
      expect(sequencer.steps.length, 2);
      expect(sequencer.totalCycleDurationSeconds, 180);
      expect(sequencer.currentStepIndex, 0);
      expect(sequencer.currentStep.id, 'sankalp');
    });

    test('skipStep advances to next step', () {
      final steps = [
        CycleStepItem(id: 'step1', title: 'Step 1', subtitle: '', durationSeconds: 60),
        CycleStepItem(id: 'step2', title: 'Step 2', subtitle: '', durationSeconds: 60),
      ];

      final sequencer = CycleSequencer(steps: steps);
      int? completedStep;

      sequencer.start(onStepComplete: (idx) {
        completedStep = idx;
      });

      expect(sequencer.currentStepIndex, 0);
      sequencer.skipStep();

      expect(completedStep, 0);
      expect(sequencer.currentStepIndex, 1);
      expect(sequencer.currentStep.id, 'step2');

      sequencer.stop();
    });

    test('skipping final step triggers onCycleComplete', () {
      final steps = [
        CycleStepItem(id: 'step1', title: 'Step 1', subtitle: '', durationSeconds: 60),
      ];

      final sequencer = CycleSequencer(steps: steps);
      bool cycleCompleted = false;

      sequencer.start(onCycleComplete: () {
        cycleCompleted = true;
      });

      sequencer.skipStep();
      expect(cycleCompleted, true);
      expect(sequencer.isCompleted, true);
    });

    test('pause and resume toggle running state', () {
      final steps = [
        CycleStepItem(id: 'step1', title: 'Step 1', subtitle: '', durationSeconds: 60),
      ];

      final sequencer = CycleSequencer(steps: steps);
      sequencer.start();
      expect(sequencer.isRunning, true);
      expect(sequencer.isPaused, false);

      sequencer.pause();
      expect(sequencer.isRunning, false);
      expect(sequencer.isPaused, true);

      sequencer.resume();
      expect(sequencer.isRunning, true);
      expect(sequencer.isPaused, false);

      sequencer.stop();
    });
  });
}
