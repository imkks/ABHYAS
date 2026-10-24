import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/audio_service.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../data/user_repository.dart';
import '../../engine/player/cycle_sequencer.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../practice/cycle_player_screen.dart';
import 'yoga_nidra_screen.dart';
import 'breath_awareness_screen.dart';
import 'progressive_japa_screen.dart';

class CustomMantra {
  final String id;
  final String name;
  final String text;
  final String? meaning;

  CustomMantra({
    required this.id,
    required this.name,
    required this.text,
    this.meaning,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'text': text,
    'meaning': meaning,
  };

  factory CustomMantra.fromJson(Map<String, dynamic> json) => CustomMantra(
    id: json['id'] as String,
    name: json['name'] as String,
    text: json['text'] as String,
    meaning: json['meaning'] as String?,
  );
}

class DhyanScreen extends StatefulWidget {
  const DhyanScreen({super.key});

  @override
  State<DhyanScreen> createState() => _DhyanScreenState();
}

class _DhyanScreenState extends State<DhyanScreen> {
  int _malaCount = 0;
  int _targetBeads = 108; // 27, 54, 108, or -1 (free)
  static const String _malaKey = 'daily_mala_count';
  static const String _customMantrasKey = 'custom_mantras_list';

  final AudioService _audioService = AudioService();

  final List<CustomMantra> _defaultMantras = [
    CustomMantra(id: 'radha', name: 'Radha Radha', text: 'राधा राधा', meaning: 'The sweet, primordial vibration of pure devotion and inner stillness.'),
    CustomMantra(id: 'om', name: 'Om (Pranava)', text: 'ॐ', meaning: 'The primordial sacred sound of creation.'),
    CustomMantra(id: 'om_namah_shivaya', name: 'Om Namah Shivaya', text: 'ॐ नमः शिवाय', meaning: 'I bow to Shiva, the auspicious witness within.'),
    CustomMantra(id: 'hare_krishna', name: 'Hare Krishna Mahamantra', text: 'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे । हरे राम हरे राम राम राम हरे हरे ॥', meaning: 'The great chant for inner liberation and divine joy.'),
    CustomMantra(id: 'soham', name: 'Soham', text: 'सो ऽहम्', meaning: 'I am That — breathing in "So", breathing out "Ham".'),
    CustomMantra(id: 'ram', name: 'Sri Rama Naam', text: 'श्री राम जय राम जय जय राम', meaning: 'Victory to the divine light within.'),
    CustomMantra(id: 'gayatri', name: 'Gayatri Mantra', text: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥', meaning: 'May divine light illuminate our intellect.'),
  ];

  List<CustomMantra> _customMantras = [];
  late CustomMantra _selectedMantra;

  @override
  void initState() {
    super.initState();
    _selectedMantra = _defaultMantras.first;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_malaKey) ?? 0;
    final rawMantras = prefs.getStringList(_customMantrasKey) ?? [];

    final userAdded = rawMantras.map((m) {
      try {
        return CustomMantra.fromJson(json.decode(m) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<CustomMantra>().toList();

    if (mounted) {
      setState(() {
        _malaCount = count;
        _customMantras = userAdded;
      });
    }
  }

  Future<void> _saveMalaCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_malaKey, count);
  }

  Future<void> _saveCustomMantras() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _customMantras.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList(_customMantrasKey, raw);
  }

  void _incrementMala() async {
    final newCount = _malaCount + 1;
    setState(() {
      _malaCount = newCount;
    });
    await _saveMalaCount(_malaCount);

    if (_targetBeads > 0 && _malaCount >= _targetBeads) {
      await Haptics.vibrate(HapticsType.heavy);
      _audioService.playBell(BellType.end);

      final sessionRepo = SessionRepository();
      await sessionRepo.logSession(SessionRecord(
        practiceName: 'Naam Jaap (${_selectedMantra.name} - $_targetBeads beads)',
        level: 1,
        durationSeconds: _targetBeads * 3,
        timestamp: DateTime.now(),
        checkinRating: 'calm',
      ));

      _showMeruDialog();
      setState(() {
        _malaCount = 0;
      });
      await _saveMalaCount(0);
    } else {
      await Haptics.vibrate(HapticsType.light);
      _audioService.playTick();
    }
  }

  void _resetMala() async {
    setState(() {
      _malaCount = 0;
    });
    await _saveMalaCount(0);
  }

  void _showMeruDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AbhyasTheme.darkSurface,
        title: const Text('Meru Reached 🙏', style: TextStyle(color: AbhyasTheme.saffron, fontWeight: FontWeight.bold)),
        content: Text(
          'You have completed $_targetBeads beads of ${_selectedMantra.name}.\n\nTurn the mala without crossing the Meru to continue or absorb the vibrations in silence.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue', style: TextStyle(color: AbhyasTheme.saffron)),
          ),
        ],
      ),
    );
  }

  void _openAddCustomMantraDialog() {
    final nameCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AbhyasTheme.darkSurface,
        title: const Text('Add Custom Mantra / Naam', style: TextStyle(color: AbhyasTheme.saffron, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. Radhe Krishna)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mantra Text (e.g. राधे राधे)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meaningCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meaning / Bhav (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AbhyasTheme.saffron, foregroundColor: Colors.black),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || textCtrl.text.trim().isEmpty) return;
              final newMantra = CustomMantra(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                text: textCtrl.text.trim(),
                meaning: meaningCtrl.text.trim().isNotEmpty ? meaningCtrl.text.trim() : null,
              );
              setState(() {
                _customMantras.add(newMantra);
                _selectedMantra = newMantra;
              });
              _saveCustomMantras();
              Navigator.pop(context);
            },
            child: const Text('Save Mantra'),
          ),
        ],
      ),
    );
  }

  /// 1-Tap Combined Meditation Flow: 3-Stage Naam Japa -> Nostril Dhyan (18 min)
  void _startCombinedMeditationFlow() async {
    final profile = await UserRepository().loadProfile() ?? SafetyProfile();

    final flowSteps = [
      CycleStepItem(
        id: 'sankalp',
        title: 'Centering & Asana',
        subtitle: 'Steady posture, hands in Chin Mudra',
        durationSeconds: 60,
      ),
      CycleStepItem(
        id: 'naam_jaap',
        title: 'Stage 1: 3-Stage Naam Japa (${_selectedMantra.name})',
        subtitle: 'Vaikhari (loud) ➔ Upamshu (murmur) ➔ Manasika (silent mind)',
        durationSeconds: 480, // 8 minutes
        isPranayamaWithPacer: false,
      ),
      CycleStepItem(
        id: 'breath_awareness',
        title: 'Stage 2: Silent Nostril Dhyan (Nasagra)',
        subtitle: 'Witnessing natural touch of air at nostril rims • Brow center stillness',
        durationSeconds: 540, // 9 minutes
        isPranayamaWithPacer: false,
      ),
    ];

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CyclePlayerScreen(
          steps: flowSteps,
          safetyProfile: profile,
        ),
      ),
    );
  }

  /// Opens the manual Digital Mala Touch Disc in an accessible modal bottom sheet
  void _openDigitalMalaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AbhyasTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AbhyasTheme.line, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Digital Mala · ${_selectedMantra.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedMantra.text,
                    style: const TextStyle(fontSize: 20, color: AbhyasTheme.saffron, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Touch Disc
                  GestureDetector(
                    onTap: () {
                      _incrementMala();
                      setSheetState(() {});
                    },
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        color: AbhyasTheme.saffron.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AbhyasTheme.saffron, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AbhyasTheme.saffron.withValues(alpha: 0.25),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_malaCount',
                              style: const TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.bold,
                                color: AbhyasTheme.saffron,
                              ),
                            ),
                            if (_targetBeads > 0)
                              Text(
                                '/ $_targetBeads',
                                style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tap disc with each repetition', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                        label: const Text('Reset', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        onPressed: () {
                          _resetMala();
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AbhyasTheme.darkSurfaceAlt, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMantras = [..._defaultMantras, ..._customMantras];

    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Dhyan Studio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fingerprint, color: AbhyasTheme.saffron),
            tooltip: 'Open Digital Mala Counter',
            onPressed: _openDigitalMalaSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white70),
            tooltip: 'Add Custom Mantra',
            onPressed: _openAddCustomMantraDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Top Master Flow: 3-Stage Naam Japa -> Nostril Dhyan
          _buildMasterFlowCard(),

          const SizedBox(height: 20),

          // 2. Active Mantra Quick Selector Strip
          _buildMantraSelectorStrip(allMantras),

          const SizedBox(height: 20),

          // 3. Section Header: Core Meditation Pillars
          const Text(
            'Core Classical Meditation Types',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Clear separation of authentic mental concentration (Dharana) and awareness practices.',
            style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Pillar 1: 3-Stage Guided Naam Japa
          _buildPillarCard(
            title: '3-Stage Naam Japa',
            subtitle: 'Vaikhari (spoken loud) ➔ Upamshu (murmur on lips) ➔ Manasika (silent inner mind).',
            icon: Icons.all_inclusive,
            color: AbhyasTheme.saffron,
            meta: 'Mantra: ${_selectedMantra.name} · 15 min',
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgressiveJapaScreen(
                    mantra: _selectedMantra,
                    targetBeads: 108,
                    isCountBased: false,
                    totalMinutes: 15,
                  ),
                ),
              );
            },
            onSecondaryAction: _openDigitalMalaSheet,
            secondaryActionLabel: 'Manual Mala Disc',
          ),

          // Pillar 2: Nostril Breath Awareness (Nasagra Prana Dharana)
          _buildPillarCard(
            title: 'Nostril Breath Awareness',
            subtitle: 'Watch natural incoming & outgoing breath at the nostril rims without force. Stillness at Ajna Chakra.',
            icon: Icons.air,
            color: Colors.tealAccent,
            meta: 'Nasagra Prana Dharana · 10 min',
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BreathAwarenessScreen(initialMinutes: 10),
                ),
              );
            },
          ),

          // Pillar 3: Guided Yoga Nidra
          _buildPillarCard(
            title: 'Yoga Nidra (Psychic Sleep)',
            subtitle: 'Systematic rotation of consciousness through the somatic body. Calms the nervous system deeply.',
            icon: Icons.bedtime,
            color: Colors.indigoAccent,
            meta: 'Somatic Relaxation · 20 min',
            onPlay: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const YogaNidraScreen(durationMinutes: 20),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Compact Focus & Stillness Section
          Card(
            color: AbhyasTheme.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AbhyasTheme.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Classical Dharana Notes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Trataka (Steady Point / Flame Concentration): Train steady gaze to quiet wandering thoughts.\n• Antar Mouna (Inner Silence): Witness thoughts with non-attachment as passing clouds.',
                    style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMasterFlowCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C223E),
            const Color(0xFF1B1627),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.4), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
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
                      child: const Icon(Icons.spa, color: AbhyasTheme.saffron, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Complete Meditation Flow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('18 min', style: TextStyle(color: AbhyasTheme.saffron, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '3-Stage Naam Japa ➔ Nostril Dhyan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AbhyasTheme.saffron),
            ),
            const SizedBox(height: 4),
            Text(
              'Start with audible & whisper Japa (${_selectedMantra.name}) to absorb wandering thoughts, then rest effortlessly into silent natural breath awareness at the nostril rims.',
              style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill, color: Colors.black, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AbhyasTheme.saffron,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _startCombinedMeditationFlow,
                label: const Text('Begin Complete Meditation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMantraSelectorStrip(List<CustomMantra> allMantras) {
    return Card(
      color: AbhyasTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          children: [
            const Icon(Icons.bookmark_border, color: AbhyasTheme.saffron, size: 20),
            const SizedBox(width: 10),
            const Text('Active Naam:', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CustomMantra>(
                  value: allMantras.firstWhere((m) => m.id == _selectedMantra.id, orElse: () => allMantras.first),
                  isExpanded: true,
                  dropdownColor: AbhyasTheme.darkSurface,
                  items: allMantras.map((m) {
                    return DropdownMenuItem<CustomMantra>(
                      value: m,
                      child: Text(
                        '${m.name} (${m.text})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newMantra) {
                    if (newMantra != null) {
                      setState(() {
                        _selectedMantra = newMantra;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String meta,
    required VoidCallback onPlay,
    VoidCallback? onSecondaryAction,
    String? secondaryActionLabel,
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(meta, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.25),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: color.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onPlay,
                    label: const Text('Start Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                if (onSecondaryAction != null && secondaryActionLabel != null) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.touch_app, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AbhyasTheme.line),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onSecondaryAction,
                    label: Text(secondaryActionLabel, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
