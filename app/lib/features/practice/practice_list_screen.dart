import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../engine/player/cycle_sequencer.dart';
import '../../engine/progression/progression_service.dart';
import '../../engine/safety/safety_rules_engine.dart';
import 'breath_capacity_test_screen.dart';
import 'cycle_composer_screen.dart';
import 'cycle_player_screen.dart';
import 'practice_player_screen.dart';

class PracticeListScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const PracticeListScreen({super.key, required this.safetyProfile});

  @override
  State<PracticeListScreen> createState() => _PracticeListScreenState();
}

class _PracticeListScreenState extends State<PracticeListScreen> {
  final ProgressionService _progressionService = ProgressionService();
  final UserRepository _userRepo = UserRepository();

  List<int> _nadiShodhanaRatio = [4, 16, 8, 4]; // Classical 1:4:2:1
  int _kapalbhatiStrokes = 30;
  int _kapalbhatiRounds = 3;
  int _ujjayiBreaths = 10;
  int _ujjayiAntarKumbhaka = 0; // 0 or 4 seconds
  int _bhramariBreaths = 7;
  int _bhramariAntarKumbhaka = 0; // 0 or 4 seconds
  int _sheetaliBreaths = 9;
  int _userLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadUserProgression();
  }

  Future<void> _loadUserProgression() async {
    final prog = await _progressionService.getProgression();
    if (mounted) {
      setState(() {
        _userLevel = prog.level;
        _nadiShodhanaRatio = prog.ratio;
        _kapalbhatiStrokes = prog.kapalbhatiStrokes;
      });
    }
  }

  void _startMasterSequence() async {
    final profile = await _userRepo.loadProfile() ?? widget.safetyProfile;

    // The Complete Classical Master Sequence (15–20 Minutes)
    final masterSteps = [
      CycleStepItem(
        id: 'sankalp',
        title: 'Sankalp & Centering',
        subtitle: 'Upright posture, Chin Mudra, spine erect',
        durationSeconds: 90,
      ),
      CycleStepItem(
        id: 'kapalbhati',
        title: 'Phase 1: Kapalbhati',
        subtitle: '3 Rounds of $_kapalbhatiStrokes strokes + 10s Antar Kumbhaka',
        durationSeconds: 240,
        isPranayamaWithPacer: true,
      ),
      CycleStepItem(
        id: 'nadi_shodhana',
        title: 'Phase 2: Nadi Shodhana',
        subtitle: 'Vishnu Mudra · Ratio ${_nadiShodhanaRatio.join(":")}',
        durationSeconds: 420,
        isPranayamaWithPacer: true,
        ratio: _nadiShodhanaRatio,
      ),
      CycleStepItem(
        id: 'ujjayi',
        title: 'Phase 3: Ujjayi Ocean Breath',
        subtitle: '5–10 deep throat constriction breaths',
        durationSeconds: 150,
        isPranayamaWithPacer: true,
      ),
      CycleStepItem(
        id: 'bhramari',
        title: 'Phase 3: Bhramari Pranayama',
        subtitle: 'Shanmukhi Mudra · 5–7 humming bee breaths',
        durationSeconds: 180,
        isPranayamaWithPacer: true,
      ),
      CycleStepItem(
        id: 'breath_awareness',
        title: 'Phase 4: Silent Nostril Dhyan',
        subtitle: 'Jnana Mudra · Witnessing breath stillness at nostril rim',
        durationSeconds: 240,
        isPranayamaWithPacer: false,
      ),
    ];

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CyclePlayerScreen(
          steps: masterSteps,
          safetyProfile: profile,
        ),
      ),
    );
  }

  void _showNadiRatioDialog() {
    int puraka = _nadiShodhanaRatio[0];
    int antar = _nadiShodhanaRatio[1];
    int rechaka = _nadiShodhanaRatio[2];
    int bahya = _nadiShodhanaRatio.length > 3 ? _nadiShodhanaRatio[3] : 0;

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
                      decoration: BoxDecoration(color: AbhyasTheme.line, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nadi Shodhana Ratio',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                  const SizedBox(height: 14),
                  const Text('CLASSICAL PRESETS', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('1:0:1:0 Sama Vritti', puraka == 4 && antar == 0 && rechaka == 4 && bahya == 0, () => applyPreset(4, 0, 4, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:0:2:0 Calming', puraka == 4 && antar == 0 && rechaka == 8 && bahya == 0, () => applyPreset(4, 0, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:1:2:0 Gentle Hold', puraka == 4 && antar == 4 && rechaka == 8 && bahya == 0, () => applyPreset(4, 4, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:2:2:0 Deep Hold', puraka == 4 && antar == 8 && rechaka == 8 && bahya == 0, () => applyPreset(4, 8, 8, 0)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:4:2:1 Master Hold', puraka == 4 && antar == 16 && rechaka == 8 && bahya == 4, () => applyPreset(4, 16, 8, 4)),
                        const SizedBox(width: 6),
                        _buildPresetChip('1:4:2:2 Maha Bandha', puraka == 4 && antar == 16 && rechaka == 8 && bahya == 8, () => applyPreset(4, 16, 8, 8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildStepperRow('Puraka (Inhale Left/Right)', puraka, 's', AbhyasTheme.sky, (v) {
                    if (v >= 2 && v <= 16) setModalState(() => puraka = v);
                  }),
                  const SizedBox(height: 8),
                  _buildStepperRow('Antar Kumbhaka (Inside Hold)', antar, 's', AbhyasTheme.saffron, (v) {
                    if (v >= 0 && v <= 32) setModalState(() => antar = v);
                  }),
                  const SizedBox(height: 8),
                  _buildStepperRow('Rechaka (Exhale Opposite)', rechaka, 's', AbhyasTheme.clay, (v) {
                    if (v >= 2 && v <= 24) setModalState(() => rechaka = v);
                  }),
                  const SizedBox(height: 8),
                  _buildStepperRow('Bahya Kumbhaka (Empty Hold)', bahya, 's', const Color(0xFF9D4EDD), (v) {
                    if (v >= 0 && v <= 16) setModalState(() => bahya = v);
                  }),
                  const SizedBox(height: 18),
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
                          _nadiShodhanaRatio = [puraka, antar, rechaka, bahya];
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: AbhyasTheme.darkInkSoft),
                onPressed: () => onChanged(value - (label.contains('Hold') ? 2 : 1)),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                alignment: Alignment.center,
                child: Text('$value$unit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: AbhyasTheme.saffron),
                onPressed: () => onChanged(value + (label.contains('Hold') ? 2 : 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Pranayama Studio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AbhyasTheme.saffron),
            tooltip: 'Routine Composer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CycleComposerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.speed, color: AbhyasTheme.saffron),
            tooltip: '1-Min Breath Capacity Test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BreathCapacityTestScreen()),
              ).then((_) => _loadUserProgression());
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Classical Master Sequence Banner
          _buildMasterSequenceBanner(),

          const SizedBox(height: 20),

          // 2. Section Header: Core Classical Pranayamas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Classical Pranayama Practices',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AbhyasTheme.saffron.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Level $_userLevel Active',
                  style: const TextStyle(color: AbhyasTheme.saffron, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Each technique follows traditional Hatha Yoga mechanics. Tap play or customize directly.',
            style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Practice 1: Nadi Shodhana (Canonical with Kumbhaka & Ratio Customizer)
          _buildPranayamaCard(
            title: 'Nadi Shodhana',
            sanskrit: 'Anuloma Viloma',
            tag: 'Purification & Balance',
            mudra: 'Vishnu Mudra (Nasika)',
            description: 'Channel purification with internal & external breath retention (Kumbhaka). Balances Ida and Pingala nadis.',
            activeSettingText: 'Ratio ${_nadiShodhanaRatio.join(":")} (Total: ${_nadiShodhanaRatio.reduce((a, b) => a + b)}s/cycle)',
            icon: Icons.air,
            accentColor: AbhyasTheme.saffron,
            onCustomize: _showNadiRatioDialog,
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: 'Nadi Shodhana',
                    practiceId: 'nadi_shodhana',
                    ratio: _nadiShodhanaRatio,
                    rounds: 7,
                  ),
                ),
              );
            },
          ),

          // Practice 2: Kapalbhati (Active Pumping + Bahir Kumbhaka)
          _buildPranayamaCard(
            title: 'Kapalbhati',
            sanskrit: 'Skull Shining Cleansing',
            tag: 'Cleansing & Heating',
            mudra: 'Chin Mudra',
            description: '30–50 rapid, sharp abdominal exhalations per round. Concludes with complete exhalation, 10s Bahir Kumbhaka (empty hold with Maha Bandha), and slow Puraka release.',
            activeSettingText: '$_kapalbhatiRounds Rounds · $_kapalbhatiStrokes strokes/round + 10s Bahir Kumbhaka',
            icon: Icons.local_fire_department,
            accentColor: Colors.deepOrange,
            onCustomize: () {
              setState(() {
                _kapalbhatiStrokes = _kapalbhatiStrokes == 30 ? 45 : (_kapalbhatiStrokes == 45 ? 60 : 30);
              });
            },
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: 'Kapalbhati',
                    practiceId: 'kapalbhati',
                    rounds: _kapalbhatiRounds,
                  ),
                ),
              );
            },
          ),

          // Practice 3: Ujjayi (Victorious Ocean Breath)
          _buildPranayamaCard(
            title: 'Ujjayi Pranayama',
            sanskrit: 'Ocean Sound Breath',
            tag: 'Soothing & Focus',
            mudra: 'Jnana Mudra',
            description: 'Gentle throat constriction producing an ocean wave sound. Optional Antar Kumbhaka internal hold for advanced soothing focus.',
            activeSettingText: '$_ujjayiBreaths Ocean Breaths · ${_ujjayiAntarKumbhaka > 0 ? "4s Antar Kumbhaka" : "Natural (No Hold)"}',
            icon: Icons.waves,
            accentColor: AbhyasTheme.sky,
            onCustomize: () {
              setState(() {
                _ujjayiAntarKumbhaka = _ujjayiAntarKumbhaka == 0 ? 4 : 0;
              });
            },
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: 'Ujjayi Pranayama',
                    practiceId: 'ujjayi',
                    ratio: [4, _ujjayiAntarKumbhaka, 5, 0],
                    rounds: _ujjayiBreaths,
                  ),
                ),
              );
            },
          ),

          // Practice 4: Bhramari (Humming Bee Breath)
          _buildPranayamaCard(
            title: 'Bhramari Pranayama',
            sanskrit: 'Humming Bee Breath',
            tag: 'Calming & Resonance',
            mudra: 'Shanmukhi Mudra',
            description: 'Smooth inhale followed by long continuous humming exhalation. Optional Antar Kumbhaka with brow focus before cranial vibration.',
            activeSettingText: '$_bhramariBreaths Humming Cycles · ${_bhramariAntarKumbhaka > 0 ? "4s Antar Kumbhaka" : "Natural (No Hold)"}',
            icon: Icons.graphic_eq,
            accentColor: Colors.tealAccent,
            onCustomize: () {
              setState(() {
                _bhramariAntarKumbhaka = _bhramariAntarKumbhaka == 0 ? 4 : 0;
              });
            },
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: 'Bhramari Pranayama',
                    practiceId: 'bhramari',
                    ratio: [4, _bhramariAntarKumbhaka, 8, 0],
                    rounds: _bhramariBreaths,
                  ),
                ),
              );
            },
          ),

          // Practice 5: Bhastrika (Bellows Breath)
          _buildPranayamaCard(
            title: 'Bhastrika',
            sanskrit: 'Bellows Breath',
            tag: 'Vitality & Solar Heat',
            mudra: 'Chin Mudra',
            description: 'Dynamic, rhythmic bellows inhalation and exhalation awakening prana, followed by deep retention with throat and root locks.',
            activeSettingText: '3 Rounds · 20 Bellows + Deep Antar Kumbhaka',
            icon: Icons.bolt,
            accentColor: Colors.amber,
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: 'Bhastrika',
                    practiceId: 'bhastrika',
                    rounds: 3,
                  ),
                ),
              );
            },
          ),

          // Practice 6: Sheetali & Sheetkari (Cooling Breath)
          _buildPranayamaCard(
            title: 'Sheetali & Sheetkari',
            sanskrit: 'Cooling Breath',
            tag: 'Cooling & Dispersing Heat',
            mudra: 'Open Mouth / Curled Tongue',
            description: 'Inhaling through a curled tongue (Sheetali) or teeth (Sheetkari) to dissipate internal fire and agitation.',
            activeSettingText: '$_sheetaliBreaths Cooling Cycles',
            icon: Icons.ac_unit,
            accentColor: Colors.cyanAccent,
            onCustomize: () {
              setState(() {
                _sheetaliBreaths = _sheetaliBreaths == 9 ? 15 : 9;
              });
            },
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: 'Sheetali Pranayama',
                    practiceId: 'sheetali',
                    rounds: _sheetaliBreaths,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 3. Clear Redirect to Dhyan Studio
          _buildDhyanRedirectBanner(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMasterSequenceBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E243A),
            const Color(0xFF1E1B2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars, color: AbhyasTheme.saffron, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'THE CLASSICAL MASTER SEQUENCE',
                    style: TextStyle(
                      color: AbhyasTheme.saffron,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('15–20 Min', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Cleansing ➔ Purification ➔ Soothing ➔ Silent Stillness',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            '1. Kapalbhati (3 rounds + 10s hold) • 2. Nadi Shodhana (Kumbhaka) • 3. Ujjayi & Bhramari • 4. Nostril Dhyan.',
            style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AbhyasTheme.saffron,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Start Master Routine (4 Phases)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: _startMasterSequence,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPranayamaCard({
    required String title,
    required String sanskrit,
    required String tag,
    required String mudra,
    required String description,
    required String activeSettingText,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onCustomize,
    required VoidCallback onPlay,
  }) {
    return Card(
      color: AbhyasTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title + Icon + Tag
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  radius: 20,
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text('$sanskrit · $mudra', style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tag, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AbhyasTheme.line),
            const SizedBox(height: 10),

            // Row 2: Active settings pill + Customize + Play
            Row(
              children: [
                Expanded(
                  child: Text(
                    activeSettingText,
                    style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCustomize != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.tune, size: 14, color: Colors.white70),
                    label: const Text('Adjust', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    onPressed: onCustomize,
                  ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: onPlay,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDhyanRedirectBanner() {
    return Card(
      color: AbhyasTheme.darkSurfaceAlt.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            const Icon(Icons.self_improvement, color: AbhyasTheme.sky, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Meditation & Dhyana Practices',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '3-Stage Naam Japa, Nostril Breath Awareness, Trataka, Antar Mouna & Yoga Nidra are in the Dhyan tab.',
                    style: TextStyle(fontSize: 11, color: AbhyasTheme.darkInkSoft, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
