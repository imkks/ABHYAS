import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../engine/player/cycle_sequencer.dart';
import '../../engine/safety/safety_rules_engine.dart';
import 'cycle_player_screen.dart';

class CycleStep {
  final String title;
  final String durationStr;
  final bool isRequired;
  bool isEnabled;

  CycleStep({
    required this.title,
    required this.durationStr,
    required this.isRequired,
    this.isEnabled = true,
  });
}

class CycleComposerScreen extends StatefulWidget {
  @override
  _CycleComposerScreenState createState() => _CycleComposerScreenState();
}

class _CycleComposerScreenState extends State<CycleComposerScreen> {
  int _selectedDuration = 30; // 10, 20, 30, 45

  // As per Section 5.2 (Default daily cycle)
  final Map<int, List<CycleStep>> _cycleMap = {
    10: [
      CycleStep(title: 'Sankalp & Invocation', durationStr: '2m', isRequired: true),
      CycleStep(title: 'Om Chanting', durationStr: '3m', isRequired: true),
      CycleStep(title: 'Breath Awareness', durationStr: '5m', isRequired: true),
    ],
    20: [
      CycleStep(title: 'Sankalp & Invocation', durationStr: '2m', isRequired: true),
      CycleStep(title: 'Warm-up / Loosening', durationStr: '2m', isRequired: false),
      CycleStep(title: 'Om Chanting', durationStr: '3m', isRequired: true),
      CycleStep(title: 'Nadi Shodhana', durationStr: '5m', isRequired: true),
      CycleStep(title: 'Breath Awareness', durationStr: '8m', isRequired: true),
    ],
    30: [
      CycleStep(title: 'Sankalp & Invocation', durationStr: '2m', isRequired: true),
      CycleStep(title: 'Warm-up / Loosening', durationStr: '2m', isRequired: false),
      CycleStep(title: 'Om Chanting', durationStr: '3m', isRequired: true),
      CycleStep(title: 'Kapalbhati', durationStr: '3m', isRequired: false),
      CycleStep(title: 'Nadi Shodhana', durationStr: '5m', isRequired: true),
      CycleStep(title: 'Ujjayi', durationStr: '3m', isRequired: false),
      CycleStep(title: 'Bhramari', durationStr: '2m', isRequired: false),
      CycleStep(title: 'Breath Awareness', durationStr: '10m', isRequired: true),
    ],
    45: [
      CycleStep(title: 'Sankalp & Invocation', durationStr: '2m', isRequired: true),
      CycleStep(title: 'Warm-up / Loosening', durationStr: '3m', isRequired: false),
      CycleStep(title: 'Om Chanting', durationStr: '5m', isRequired: true),
      CycleStep(title: 'Kapalbhati', durationStr: '5m', isRequired: false),
      CycleStep(title: 'Nadi Shodhana', durationStr: '8m', isRequired: true),
      CycleStep(title: 'Ujjayi', durationStr: '5m', isRequired: false),
      CycleStep(title: 'Bhramari', durationStr: '2m', isRequired: false),
      CycleStep(title: 'Breath Awareness', durationStr: '15m', isRequired: true),
    ],
  };

  @override
  Widget build(BuildContext context) {
    List<CycleStep> currentCycle = _cycleMap[_selectedDuration]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Cycle Composer'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Segment Selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              border: Border(bottom: BorderSide(color: AbhyasTheme.line, width: 1)),
            ),
            child: Column(
              children: [
                SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AbhyasTheme.darkSurfaceAlt,
                    selectedBackgroundColor: AbhyasTheme.saffron,
                    selectedForegroundColor: AbhyasTheme.darkBg,
                  ),
                  segments: const [
                    ButtonSegment(value: 10, label: Text('10m')),
                    ButtonSegment(value: 20, label: Text('20m')),
                    ButtonSegment(value: 30, label: Text('30m')),
                    ButtonSegment(value: 45, label: Text('45m')),
                  ],
                  selected: {_selectedDuration},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedDuration = newSelection.first;
                    });
                  },
                ),
                SizedBox(height: 12),
                Text(
                  'Traditional sequence locked. You may skip optional steps.',
                  style: TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Timeline list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: currentCycle.length,
              itemBuilder: (context, index) {
                final step = currentCycle[index];
                final bool isFirst = index == 0;
                final bool isLast = index == currentCycle.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline graphical node
                      Container(
                        width: 32,
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 16,
                              color: isFirst ? Colors.transparent : AbhyasTheme.line,
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: step.isEnabled ? AbhyasTheme.leaf : AbhyasTheme.line,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isLast ? Colors.transparent : AbhyasTheme.line,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: step.isEnabled ? AbhyasTheme.line : Colors.transparent,
                              )
                            ),
                            color: step.isEnabled ? AbhyasTheme.darkSurface : AbhyasTheme.darkSurfaceAlt.withOpacity(0.5),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text(
                                step.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: step.isEnabled ? AbhyasTheme.darkInk : AbhyasTheme.darkInkSoft,
                                  decoration: step.isEnabled ? TextDecoration.none : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Text(
                                step.durationStr,
                                style: TextStyle(color: step.isEnabled ? AbhyasTheme.saffron : AbhyasTheme.darkInkSoft),
                              ),
                              trailing: step.isRequired
                                ? Icon(Icons.lock_outline, color: AbhyasTheme.darkInkSoft, size: 20)
                                : Switch(
                                    value: step.isEnabled,
                                    activeColor: AbhyasTheme.saffron,
                                    onChanged: (val) {
                                      setState(() {
                                        step.isEnabled = val;
                                      });
                                    },
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              border: Border(top: BorderSide(color: AbhyasTheme.line, width: 1)),
            ),
            child: ElevatedButton.icon(
              icon: Icon(Icons.play_circle_fill),
              onPressed: () async {
                final enabledSteps = currentCycle.where((s) => s.isEnabled).toList();
                if (enabledSteps.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enable at least one practice step.')),
                  );
                  return;
                }

                int parseDurationSeconds(String str) {
                  if (str.endsWith('m')) {
                    return (int.tryParse(str.replaceAll('m', '')) ?? 1) * 60;
                  } else if (str.endsWith('s')) {
                    return int.tryParse(str.replaceAll('s', '')) ?? 30;
                  }
                  return 60;
                }

                final items = enabledSteps.map((s) => CycleStepItem(
                  id: s.title.toLowerCase().replaceAll(' ', '_'),
                  title: s.title,
                  subtitle: '${s.durationStr} session',
                  durationSeconds: parseDurationSeconds(s.durationStr),
                  isRequired: s.isRequired,
                )).toList();

                final profile = await UserRepository().loadProfile() ?? SafetyProfile();

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CyclePlayerScreen(
                      steps: items,
                      safetyProfile: profile,
                    ),
                  ),
                );
              },
              label: Text('Begin Cycle', style: TextStyle(fontSize: 18, letterSpacing: 1.1)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
              ),
            ),
          )
        ],
      ),
    );
  }
}
