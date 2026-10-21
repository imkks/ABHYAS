import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../engine/player/cycle_sequencer.dart';
import '../../engine/progression/progression_service.dart';
import '../../engine/safety/safety_rules_engine.dart';
import 'breath_capacity_test_screen.dart';
import 'cycle_player_screen.dart';

enum RoutinePreset {
  surya, // Morning Vitality
  chandra, // Night Bedtime (Naam Jaap, Bhramari, Yoga Nidra)
  custom, // Custom / Flexible
}

enum RoutineIntensity {
  gentle, // Level 1 gentle pacing
  adaptive, // Matched to user's active Sopana level
  intense, // Advanced challenge
}

class CycleStep {
  final String id;
  String title;
  String subtitle;
  int durationMinutes;
  final bool isRequired;
  bool isEnabled;
  final bool isPranayamaWithPacer;
  final List<int>? ratio;

  CycleStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    this.isRequired = false,
    this.isEnabled = true,
    this.isPranayamaWithPacer = false,
    this.ratio,
  });

  CycleStep copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? durationMinutes,
    bool? isRequired,
    bool? isEnabled,
    bool? isPranayamaWithPacer,
    List<int>? ratio,
  }) {
    return CycleStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isRequired: isRequired ?? this.isRequired,
      isEnabled: isEnabled ?? this.isEnabled,
      isPranayamaWithPacer: isPranayamaWithPacer ?? this.isPranayamaWithPacer,
      ratio: ratio ?? this.ratio,
    );
  }
}

class CycleComposerScreen extends StatefulWidget {
  final RoutinePreset initialPreset;
  final int initialDuration;

  const CycleComposerScreen({
    super.key,
    this.initialPreset = RoutinePreset.surya,
    this.initialDuration = 30,
  });

  @override
  State<CycleComposerScreen> createState() => _CycleComposerScreenState();
}

class _CycleComposerScreenState extends State<CycleComposerScreen> {
  late RoutinePreset _selectedPreset;
  late int _selectedTargetDuration;
  RoutineIntensity _selectedIntensity = RoutineIntensity.adaptive;
  int _userLevel = 1;
  String _levelTitle = 'Prarambha';
  String _levelHighlight = 'Foundational breath';
  late List<CycleStep> _steps;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _selectedTargetDuration = widget.initialDuration;
    _steps = [];
    _initLevelAndSteps();
  }

  Future<void> _initLevelAndSteps() async {
    final prog = await ProgressionService().getProgression();
    if (mounted) {
      setState(() {
        _userLevel = prog.level;
        _levelTitle = prog.title;
        _levelHighlight = prog.featureHighlight;
        _loadPresetSteps(_selectedPreset, _selectedTargetDuration);
      });
    }
  }

  int get _effectiveLevel {
    switch (_selectedIntensity) {
      case RoutineIntensity.gentle:
        return 1;
      case RoutineIntensity.intense:
        return (_userLevel + 1).clamp(1, 7);
      case RoutineIntensity.adaptive:
      default:
        return _userLevel;
    }
  }

  void _loadPresetSteps(RoutinePreset preset, int duration) {
    final level = _effectiveLevel;
    final levelInfo = ProgressionService().getLevelInfo(level);

    if (preset == RoutinePreset.surya) {
      // 🌅 Surya Abhyas: Scaled to level
      String nadiSub = '1:0:1:0 Natural Balance';
      String kapalbhatiSub = '30 strokes/round gentle cleanse';
      String ujjayiSub = 'Ocean breath focus';

      if (level == 2) {
        nadiSub = '1:0:2:0 Extended Exhale (Calming)';
        kapalbhatiSub = '45 strokes/round rhythmic';
      } else if (level == 3) {
        nadiSub = '1:1:2:0 Antar Kumbhaka + Jalandhara';
        kapalbhatiSub = '60 strokes/round channel cleanse';
        ujjayiSub = 'Ujjayi + Throat awareness';
      } else if (level >= 4) {
        nadiSub = '1:2:2:0 Deep Hold + Mula Bandha';
        kapalbhatiSub = '80 strokes/round + Solar heat';
      }

      if (duration <= 15) {
        _steps = [
          CycleStep(id: 'sankalp', title: 'Sankalp & Invocation', subtitle: 'Setting sacred intention', durationMinutes: 2),
          CycleStep(id: 'kapalbhati', title: 'Kapalbhati (Level $level)', subtitle: kapalbhatiSub, durationMinutes: 3, isPranayamaWithPacer: true),
          CycleStep(id: 'nadi_shodhana', title: 'Nadi Shodhana (Level $level)', subtitle: nadiSub, durationMinutes: 5, isPranayamaWithPacer: true, ratio: levelInfo.ratio),
          CycleStep(id: 'breath_awareness', title: 'Breath Awareness Dhyan', subtitle: 'Witnessing natural stillness', durationMinutes: 5),
        ];
      } else if (duration <= 25) {
        _steps = [
          CycleStep(id: 'sankalp', title: 'Sankalp & Invocation', subtitle: 'Setting intention', durationMinutes: 2),
          CycleStep(id: 'kapalbhati', title: 'Kapalbhati (Level $level)', subtitle: kapalbhatiSub, durationMinutes: 4, isPranayamaWithPacer: true),
          CycleStep(id: 'nadi_shodhana', title: 'Nadi Shodhana (Level $level)', subtitle: nadiSub, durationMinutes: 6, isPranayamaWithPacer: true, ratio: levelInfo.ratio),
          CycleStep(id: 'ujjayi', title: 'Ujjayi Pranayama', subtitle: ujjayiSub, durationMinutes: 3, isPranayamaWithPacer: true),
          CycleStep(id: 'breath_awareness', title: 'Breath Awareness Dhyan', subtitle: 'Stillness meditation', durationMinutes: 8),
          CycleStep(id: 'shanti_path', title: 'Shanti Path', subtitle: 'Peace closing prayer', durationMinutes: 2),
        ];
      } else if (duration <= 35) {
        // Default 30 min morning routine
        _steps = [
          CycleStep(id: 'sankalp', title: 'Sankalp & Invocation', subtitle: 'Setting intention & Om', durationMinutes: 2),
          CycleStep(id: 'warmup', title: 'Sukshma Vyayama', subtitle: 'Gentle joint loosening', durationMinutes: 2),
          CycleStep(id: 'kapalbhati', title: 'Kapalbhati (Level $level)', subtitle: kapalbhatiSub, durationMinutes: 4, isPranayamaWithPacer: true),
          CycleStep(id: 'nadi_shodhana', title: 'Nadi Shodhana (Level $level)', subtitle: nadiSub, durationMinutes: 8, isPranayamaWithPacer: true, ratio: levelInfo.ratio),
          CycleStep(id: 'ujjayi', title: 'Ujjayi Pranayama', subtitle: ujjayiSub, durationMinutes: 4, isPranayamaWithPacer: true),
          CycleStep(id: 'breath_awareness', title: 'Breath Awareness Dhyan', subtitle: 'Witnessing stillness', durationMinutes: 8),
          CycleStep(id: 'shanti_path', title: 'Shanti Path', subtitle: 'Universal peace chant', durationMinutes: 2),
        ];
      } else {
        // 45m - 60m extended morning sadhana
        _steps = [
          CycleStep(id: 'sankalp', title: 'Sankalp & Invocation', subtitle: 'Setting sacred intention', durationMinutes: 3),
          CycleStep(id: 'warmup', title: 'Sukshma Vyayama', subtitle: 'Prana loosening', durationMinutes: 4),
          CycleStep(id: 'kapalbhati', title: 'Kapalbhati (Level $level)', subtitle: kapalbhatiSub, durationMinutes: 6, isPranayamaWithPacer: true),
          CycleStep(id: 'nadi_shodhana', title: 'Nadi Shodhana (Level $level)', subtitle: nadiSub, durationMinutes: 10, isPranayamaWithPacer: true, ratio: levelInfo.ratio),
          CycleStep(id: 'bhastrika', title: 'Bhastrika / Surya Bhedana', subtitle: 'Vital solar activation', durationMinutes: 5, isPranayamaWithPacer: true),
          CycleStep(id: 'ujjayi', title: 'Ujjayi Pranayama', subtitle: ujjayiSub, durationMinutes: 5, isPranayamaWithPacer: true),
          CycleStep(id: 'breath_awareness', title: 'Antar Mouna / Dhyan', subtitle: 'Deep meditative stillness', durationMinutes: 10),
          CycleStep(id: 'shanti_path', title: 'Shanti Path', subtitle: 'Closing integration', durationMinutes: 2),
        ];
      }
    } else if (preset == RoutinePreset.chandra) {
      // 🌙 Chandra Abhyas: Night Bedtime Routine
      if (duration <= 20) {
        _steps = [
          CycleStep(id: 'naam_jaap', title: 'Naam Jaap (Digital Mala)', subtitle: '108 bead sacred recitation', durationMinutes: 5),
          CycleStep(id: 'bhramari', title: 'Bhramari Pranayama', subtitle: 'Humming bee breath for calming', durationMinutes: 5, isPranayamaWithPacer: true),
          CycleStep(id: 'yoga_nidra', title: 'Yoga Nidra', subtitle: 'Conscious deep relaxation for sleep', durationMinutes: 10),
        ];
      } else if (duration <= 30) {
        // Default 25-30 min evening routine
        _steps = [
          CycleStep(id: 'naam_jaap', title: 'Naam Jaap (Digital Mala)', subtitle: '108 bead meditative japa', durationMinutes: 5),
          CycleStep(id: 'bhramari', title: 'Bhramari Pranayama', subtitle: 'Humming bee breath to soothe nerves', durationMinutes: 5, isPranayamaWithPacer: true),
          CycleStep(id: 'yoga_nidra', title: 'Yoga Nidra', subtitle: 'Guided deep conscious sleep', durationMinutes: 15),
        ];
      } else {
        // 40m - 45m extended evening relaxation
        _steps = [
          CycleStep(id: 'naam_jaap', title: 'Naam Jaap (Digital Mala)', subtitle: 'Extended Japa recitation', durationMinutes: 10),
          CycleStep(id: 'sheetali', title: 'Sheetali / Chandra Bhedana', subtitle: 'Cooling lunar breath', durationMinutes: 5, isPranayamaWithPacer: true),
          CycleStep(id: 'bhramari', title: 'Bhramari Pranayama', subtitle: 'Deep humming vibration', durationMinutes: 5, isPranayamaWithPacer: true),
          CycleStep(id: 'yoga_nidra', title: 'Yoga Nidra', subtitle: 'Full 20-min psychic sleep induction', durationMinutes: 20),
        ];
      }
    } else {
      // ⚙️ Custom / Modular Routine
      _steps = [
        CycleStep(id: 'sankalp', title: 'Sankalp & Invocation', subtitle: 'Intention setting', durationMinutes: 2),
        CycleStep(id: 'kapalbhati', title: 'Kapalbhati', subtitle: 'Active cleansing', durationMinutes: 4, isPranayamaWithPacer: true),
        CycleStep(id: 'nadi_shodhana', title: 'Nadi Shodhana', subtitle: 'Channel balancing', durationMinutes: 6, isPranayamaWithPacer: true),
        CycleStep(id: 'bhramari', title: 'Bhramari', subtitle: 'Calming vibration', durationMinutes: 3, isPranayamaWithPacer: true),
        CycleStep(id: 'breath_awareness', title: 'Breath Awareness Dhyan', subtitle: 'Silent meditation', durationMinutes: 8),
      ];
    }
  }

  int get _totalMinutes => _steps
      .where((s) => s.isEnabled)
      .fold(0, (sum, step) => sum + step.durationMinutes);

  void _onPresetChanged(RoutinePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _loadPresetSteps(_selectedPreset, _selectedTargetDuration);
    });
  }

  void _onIntensityChanged(RoutineIntensity intensity) {
    setState(() {
      _selectedIntensity = intensity;
      _loadPresetSteps(_selectedPreset, _selectedTargetDuration);
    });
  }

  void _onDurationSelected(int minutes) {
    setState(() {
      _selectedTargetDuration = minutes;
      _loadPresetSteps(_selectedPreset, _selectedTargetDuration);
    });
  }

  void _adjustStepDuration(int index, int delta) {
    setState(() {
      final newDuration = (_steps[index].durationMinutes + delta).clamp(1, 45);
      _steps[index].durationMinutes = newDuration;
    });
  }

  void _toggleStepEnabled(int index) {
    setState(() {
      _steps[index].isEnabled = !_steps[index].isEnabled;
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _moveStep(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
  }

  void _openAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AbhyasTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final List<Map<String, dynamic>> catalog = [
          // Pranayamas
          {'id': 'nadi_shodhana', 'title': 'Nadi Shodhana', 'category': 'Pranayama', 'sub': 'Alternate nostril balance', 'defaultMin': 6, 'isPacer': true},
          {'id': 'kapalbhati', 'title': 'Kapalbhati', 'category': 'Pranayama', 'sub': 'Cleansing frontal brain', 'defaultMin': 4, 'isPacer': true},
          {'id': 'bhramari', 'title': 'Bhramari', 'category': 'Pranayama', 'sub': 'Humming bee calming breath', 'defaultMin': 4, 'isPacer': true},
          {'id': 'ujjayi', 'title': 'Ujjayi', 'category': 'Pranayama', 'sub': 'Ocean sound deep breathing', 'defaultMin': 4, 'isPacer': true},
          {'id': 'sheetali', 'title': 'Sheetali', 'category': 'Pranayama', 'sub': 'Cooling tongue breath', 'defaultMin': 3, 'isPacer': true},
          {'id': 'bhastrika', 'title': 'Bhastrika', 'category': 'Pranayama', 'sub': 'Bellows breath for prana energy', 'defaultMin': 4, 'isPacer': true},
          {'id': 'surya_bhedana', 'title': 'Surya Bhedana', 'category': 'Pranayama', 'sub': 'Right nostril heating breath', 'defaultMin': 4, 'isPacer': true},
          // Dhyan & Meditation
          {'id': 'breath_awareness', 'title': 'Breath Awareness Dhyan', 'category': 'Dhyan', 'sub': 'Witnessing natural incoming/outgoing prana', 'defaultMin': 8, 'isPacer': false},
          {'id': 'antar_mouna', 'title': 'Antar Mouna', 'category': 'Dhyan', 'sub': 'Inner silence & observing thought ripples', 'defaultMin': 10, 'isPacer': false},
          {'id': 'trataka', 'title': 'Trataka (Gazing)', 'category': 'Dhyan', 'sub': 'Single-point concentration meditation', 'defaultMin': 5, 'isPacer': false},
          // Mantra & Japa
          {'id': 'naam_jaap', 'title': 'Naam Jaap (Digital Mala)', 'category': 'Mantra & Japa', 'sub': '108 bead meditative japa recitation', 'defaultMin': 5, 'isPacer': false},
          {'id': 'om_chant', 'title': 'Om Chanting', 'category': 'Mantra & Japa', 'sub': 'Primordial sound vibration (A-U-M)', 'defaultMin': 3, 'isPacer': false},
          {'id': 'gayatri_mantra', 'title': 'Gayatri Mantra', 'category': 'Mantra & Japa', 'sub': 'Illumination of the intellect', 'defaultMin': 5, 'isPacer': false},
          // Restorative
          {'id': 'yoga_nidra', 'title': 'Yoga Nidra', 'category': 'Restorative', 'sub': 'Conscious deep psychic sleep & rejuvenation', 'defaultMin': 15, 'isPacer': false},
          {'id': 'savasana', 'title': 'Savasana Integration', 'category': 'Restorative', 'sub': 'Complete physical and mental surrender', 'defaultMin': 5, 'isPacer': false},
          // Preparation
          {'id': 'sankalp', 'title': 'Sankalp & Invocation', 'category': 'Preparation', 'sub': 'Awakening intention & guru prayer', 'defaultMin': 2, 'isPacer': false},
          {'id': 'warmup', 'title': 'Sukshma Vyayama', 'category': 'Preparation', 'sub': 'Joint loosening & spinal preparation', 'defaultMin': 3, 'isPacer': false},
        ];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AbhyasTheme.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Practice Step',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AbhyasTheme.line),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: catalog.length,
                    itemBuilder: (context, idx) {
                      final item = catalog[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AbhyasTheme.saffron.withValues(alpha: 0.15),
                          child: Icon(
                            item['isPacer'] ? Icons.air : Icons.spa,
                            color: AbhyasTheme.saffron,
                            size: 20,
                          ),
                        ),
                        title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['category']} · ${item['sub']}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AbhyasTheme.darkSurfaceAlt,
                            foregroundColor: AbhyasTheme.saffron,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              _steps.add(CycleStep(
                                id: item['id'] as String,
                                title: item['title'] as String,
                                subtitle: item['sub'] as String,
                                durationMinutes: item['defaultMin'] as int,
                                isPranayamaWithPacer: item['isPacer'] as bool,
                              ));
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('+ Add'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _beginCycle() async {
    final enabledSteps = _steps.where((s) => s.isEnabled).toList();
    if (enabledSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable at least one practice step.')),
      );
      return;
    }

    final items = enabledSteps.map((s) => CycleStepItem(
      id: s.id,
      title: s.title,
      subtitle: '${s.durationMinutes} min session',
      durationSeconds: s.durationMinutes * 60,
      isRequired: s.isRequired,
      isPranayamaWithPacer: s.isPranayamaWithPacer,
      ratio: s.ratio,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Routine Planner'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.speed, color: AbhyasTheme.saffron),
            tooltip: 'Find My Apt Level (Breath Test)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BreathCapacityTestScreen()),
              ).then((_) => _initLevelAndSteps());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AbhyasTheme.saffron),
            tooltip: 'Add Exercise',
            onPressed: _openAddExerciseSheet,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preset Tabs (Morning / Night / Custom)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF191824),
              border: Border(bottom: BorderSide(color: AbhyasTheme.line, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPresetTab(
                    preset: RoutinePreset.surya,
                    icon: Icons.wb_sunny_rounded,
                    title: 'Morning',
                    subtitle: 'Pranayama & Dhyan',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPresetTab(
                    preset: RoutinePreset.chandra,
                    icon: Icons.bedtime_rounded,
                    title: 'Night',
                    subtitle: 'Naam Jaap & Nidra',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPresetTab(
                    preset: RoutinePreset.custom,
                    icon: Icons.tune_rounded,
                    title: 'Custom',
                    subtitle: 'Open Sadhana',
                  ),
                ),
              ],
            ),
          ),

          // Intensity Mode Bar
          if (_selectedPreset == RoutinePreset.surya)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1F1D2B),
              child: Row(
                children: [
                  const Text('Intensity: ', style: TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIntensityChip(RoutineIntensity.gentle, '🍃 Gentle'),
                        _buildIntensityChip(RoutineIntensity.adaptive, '⚡ Level $_userLevel Adapt'),
                        _buildIntensityChip(RoutineIntensity.intense, '🔥 Intense'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Duration Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AbhyasTheme.darkSurface,
            child: Row(
              children: [
                const Text(
                  'Duration:',
                  style: TextStyle(fontSize: 13, color: AbhyasTheme.darkInkSoft, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [10, 15, 20, 25, 30, 45, 60].map((min) {
                        final isSelected = _selectedTargetDuration == min;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text('${min}m'),
                            selected: isSelected,
                            selectedColor: AbhyasTheme.saffron,
                            backgroundColor: AbhyasTheme.darkSurfaceAlt,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _onDurationSelected(min),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Time Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: const Color(0xFF14121F),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_steps.where((s) => s.isEnabled).length} steps selected',
                  style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AbhyasTheme.saffron),
                    const SizedBox(width: 4),
                    Text(
                      'Total: $_totalMinutes mins',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AbhyasTheme.saffron,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reorderable Steps List
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _steps.length,
              onReorder: _moveStep,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Padding(
                  key: ValueKey('${step.id}_$index'),
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: step.isEnabled ? AbhyasTheme.line : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    color: step.isEnabled
                        ? AbhyasTheme.darkSurface
                        : AbhyasTheme.darkSurfaceAlt.withValues(alpha: 0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ROW 1: Drag handle + Title & Subtitle + Enable Switch
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Drag Handle
                              ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.drag_indicator_rounded,
                                    color: AbhyasTheme.darkInkSoft,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Exercise Title and Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: step.isEnabled ? Colors.white : Colors.white38,
                                        decoration: step.isEnabled ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.subtitle,
                                      style: TextStyle(
                                        color: step.isEnabled ? AbhyasTheme.darkInkSoft : Colors.white24,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Enable/Disable Switch
                              Switch(
                                value: step.isEnabled,
                                activeColor: AbhyasTheme.saffron,
                                onChanged: (_) => _toggleStepEnabled(index),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AbhyasTheme.line),
                          const SizedBox(height: 8),

                          // ROW 2: Category Badge + Stepper Controls + Delete Action
                          Row(
                            children: [
                              // Category Badge
                              if (step.isPranayamaWithPacer) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AbhyasTheme.leaf.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AbhyasTheme.leaf.withValues(alpha: 0.35)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.air, size: 12, color: AbhyasTheme.leaf),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pranayama',
                                        style: TextStyle(
                                          color: AbhyasTheme.leaf,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showRatioCustomizer(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AbhyasTheme.saffron.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.tune, size: 12, color: AbhyasTheme.saffron),
                                        const SizedBox(width: 4),
                                        Text(
                                          step.ratio != null ? 'Ratio ${step.ratio!.join(":")}' : 'Ratio 1:0:1:0',
                                          style: const TextStyle(
                                            color: AbhyasTheme.saffron,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AbhyasTheme.sky.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AbhyasTheme.sky.withValues(alpha: 0.35)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.spa, size: 12, color: AbhyasTheme.sky),
                                      SizedBox(width: 4),
                                      Text(
                                        'Meditation',
                                        style: TextStyle(
                                          color: AbhyasTheme.sky,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const Spacer(),

                              // Duration Stepper Pill: [-] 2 min [+]
                              Container(
                                decoration: BoxDecoration(
                                  color: AbhyasTheme.darkSurfaceAlt,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AbhyasTheme.line),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: step.isEnabled ? () => _adjustStepDuration(index, -1) : null,
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        child: Icon(Icons.remove, size: 16, color: Colors.white70),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      child: Text(
                                        '${step.durationMinutes} min',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: step.isEnabled ? AbhyasTheme.saffron : Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: step.isEnabled ? () => _adjustStepDuration(index, 1) : null,
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        child: Icon(Icons.add, size: 16, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Delete Action
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: Colors.red.withValues(alpha: 0.65),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeStep(index),
                                tooltip: 'Remove step',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: const BoxDecoration(
              color: Color(0xFF191824),
              border: Border(top: BorderSide(color: AbhyasTheme.line, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Step'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AbhyasTheme.line),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openAddExerciseSheet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.black, size: 20),
                    label: Text(
                      'Begin ($_totalMinutes m)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AbhyasTheme.saffron,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _beginCycle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityChip(RoutineIntensity intensity, String label) {
    final isSelected = _selectedIntensity == intensity;
    return InkWell(
      onTap: () => _onIntensityChanged(intensity),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AbhyasTheme.saffron.withValues(alpha: 0.25) : AbhyasTheme.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AbhyasTheme.saffron : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AbhyasTheme.saffron : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetTab({
    required RoutinePreset preset,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedPreset == preset;
    return InkWell(
      onTap: () => _onPresetChanged(preset),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AbhyasTheme.saffron.withValues(alpha: 0.15) : AbhyasTheme.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AbhyasTheme.saffron : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AbhyasTheme.saffron : Colors.white70,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? AbhyasTheme.saffron : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AbhyasTheme.saffron.withValues(alpha: 0.85) : AbhyasTheme.darkInkSoft,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AbhyasTheme.saffron.withValues(alpha: 0.25) : AbhyasTheme.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AbhyasTheme.saffron : AbhyasTheme.line,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AbhyasTheme.saffron : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildStepperRow(String label, int value, String unit, Color color, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AbhyasTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AbhyasTheme.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 22, color: AbhyasTheme.darkInkSoft),
                onPressed: () => onChanged(value - (label.contains('Hold') ? 2 : 1)),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 42),
                alignment: Alignment.center,
                child: Text(
                  '$value$unit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22, color: AbhyasTheme.saffron),
                onPressed: () => onChanged(value + (label.contains('Hold') ? 2 : 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRatioCustomizer(int index) {
    final step = _steps[index];
    final currentRatio = List<int>.from(step.ratio ?? [4, 0, 4, 0]);
    while (currentRatio.length < 4) {
      currentRatio.add(0);
    }

    int puraka = currentRatio[0];
    int antar = currentRatio[1];
    int rechaka = currentRatio[2];
    int bahya = currentRatio[3];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AbhyasTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cycleTotal = puraka + antar + rechaka + bahya;

            void applyPreset(int p, int a, int r, int b) {
              setModalState(() {
                puraka = p;
                antar = a;
                rechaka = r;
                bahya = b;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AbhyasTheme.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customize Breath Ratio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(step.title, style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AbhyasTheme.saffron.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '$puraka : $antar : $rechaka : $bahya',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AbhyasTheme.saffron, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Classical Presets Chips
                  const Text('CLASSICAL RATIO PRESETS', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('1:0:1:0 Sama Vritti', puraka == 4 && antar == 0 && rechaka == 4 && bahya == 0, () => applyPreset(4, 0, 4, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:0:2:0 Relaxing', puraka == 4 && antar == 0 && rechaka == 8 && bahya == 0, () => applyPreset(4, 0, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:1:2:0 Gentle Hold', puraka == 4 && antar == 4 && rechaka == 8 && bahya == 0, () => applyPreset(4, 4, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:2:2:0 Deep Hold', puraka == 4 && antar == 8 && rechaka == 8 && bahya == 0, () => applyPreset(4, 8, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:4:2:0 Classical', puraka == 4 && antar == 16 && rechaka == 8 && bahya == 0, () => applyPreset(4, 16, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:4:2:2 Maha Bandha', puraka == 4 && antar == 16 && rechaka == 8 && bahya == 8, () => applyPreset(4, 16, 8, 8)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Interactive Steppers
                  _buildStepperRow('Puraka (Inhale)', puraka, 's', AbhyasTheme.sky, (val) {
                    if (val >= 2 && val <= 16) setModalState(() => puraka = val);
                  }),
                  const SizedBox(height: 10),
                  _buildStepperRow('Antar Kumbhaka (Hold)', antar, 's', AbhyasTheme.saffron, (val) {
                    if (val >= 0 && val <= 32) setModalState(() => antar = val);
                  }),
                  const SizedBox(height: 10),
                  _buildStepperRow('Rechaka (Exhale)', rechaka, 's', AbhyasTheme.clay, (val) {
                    if (val >= 2 && val <= 24) setModalState(() => rechaka = val);
                  }),
                  const SizedBox(height: 10),
                  _buildStepperRow('Bahya Kumbhaka (Hold Empty)', bahya, 's', const Color(0xFF9D4EDD), (val) {
                    if (val >= 0 && val <= 16) setModalState(() => bahya = val);
                  }),

                  const SizedBox(height: 16),

                  // Breath Test Link
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BreathCapacityTestScreen()),
                      ).then((_) => _initLevelAndSteps());
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AbhyasTheme.darkSurfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.speed, size: 16, color: AbhyasTheme.saffron),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unsure of your hold capacity? Take the 1-Min Breath Test',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 12, color: AbhyasTheme.darkInkSoft),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AbhyasTheme.saffron,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _steps[index] = step.copyWith(
                            ratio: [puraka, antar, rechaka, bahya],
                            subtitle: '$puraka:$antar:$rechaka:$bahya ratio (${cycleTotal}s cycle)',
                          );
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text('Save Ratio ($puraka:$antar:$rechaka:$bahya)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
