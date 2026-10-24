import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/audio_service.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
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
    CustomMantra(id: 'om', name: 'Om (Pranava)', text: 'ॐ', meaning: 'The primordial sacred sound of creation.'),
    CustomMantra(id: 'om_namah_shivaya', name: 'Om Namah Shivaya', text: 'ॐ नमः शिवाय', meaning: 'I bow to Shiva, the inner auspicious self.'),
    CustomMantra(id: 'hare_krishna', name: 'Hare Krishna Mahamantra', text: 'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे । हरे राम हरे राम राम राम हरे हरे ॥', meaning: 'The great chant for peace and spiritual joy.'),
    CustomMantra(id: 'gayatri', name: 'Gayatri Mantra', text: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥', meaning: 'May the supreme divine light illuminate our intellect.'),
    CustomMantra(id: 'soham', name: 'Soham', text: 'सो ऽहम्', meaning: 'I am That — breathing in "So", breathing out "Ham".'),
    CustomMantra(id: 'ram', name: 'Sri Rama Naam', text: 'श्री राम जय राम जय जय राम', meaning: 'Victory to the divine light within.'),
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
                  labelText: 'Mantra Name / Ishta Devata',
                  hintText: 'e.g., Radhe Krishna, Shiva Dhyan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mantra Text / Chant',
                  hintText: 'e.g., राधे राधे or Sanskrit text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meaningCtrl,
                decoration: const InputDecoration(
                  labelText: 'Meaning / Intention (Optional)',
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

  @override
  Widget build(BuildContext context) {
    final allMantras = [..._defaultMantras, ..._customMantras];

    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Dhyan & Naam Jaap'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Custom Mantra',
            onPressed: _openAddCustomMantraDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Mantra Selector Card
          Card(
            color: AbhyasTheme.darkSurface,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Active Mantra / Naam',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AbhyasTheme.darkInkSoft),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: AbhyasTheme.saffron),
                        label: const Text('Add Custom', style: TextStyle(color: AbhyasTheme.saffron, fontSize: 12)),
                        onPressed: _openAddCustomMantraDialog,
                      ),
                    ],
                  ),
                  DropdownButton<CustomMantra>(
                    value: allMantras.firstWhere((m) => m.id == _selectedMantra.id, orElse: () => allMantras.first),
                    isExpanded: true,
                    dropdownColor: AbhyasTheme.darkSurface,
                    underline: Container(height: 1, color: AbhyasTheme.saffron),
                    items: allMantras.map((m) {
                      return DropdownMenuItem<CustomMantra>(
                        value: m,
                        child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.darkSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _selectedMantra.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AbhyasTheme.saffron,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedMantra.meaning != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _selectedMantra.meaning!,
                            style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bead Count Segmented Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Target Beads: ', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
              const SizedBox(width: 8),
              ...[27, 54, 108, -1].map((count) {
                final isSelected = _targetBeads == count;
                final label = count == -1 ? 'Free' : '$count';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AbhyasTheme.saffron,
                    backgroundColor: AbhyasTheme.darkSurfaceAlt,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _targetBeads = count;
                      });
                    },
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Digital Mala Touch Disc
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: AbhyasTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _incrementMala,
                    child: Container(
                      height: 190,
                      width: 190,
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
                                fontSize: 62,
                                fontWeight: FontWeight.bold,
                                color: AbhyasTheme.saffron,
                              ),
                            ),
                            if (_targetBeads > 0)
                              Text(
                                '/ $_targetBeads',
                                style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Tap circle or bead to advance count', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13)),
                  const SizedBox(height: 10),
                  if (_targetBeads > 0)
                    LinearProgressIndicator(
                      value: (_malaCount / _targetBeads).clamp(0.0, 1.0),
                      backgroundColor: AbhyasTheme.darkSurfaceAlt,
                      color: AbhyasTheme.saffron,
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                    label: const Text('Reset Counter', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    onPressed: _resetMala,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AbhyasTheme.saffron,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.all_inclusive, size: 20),
            label: const Text(
              'Guided 3-Stage Japa (Vaikhari ➔ Upamshu ➔ Manasika)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgressiveJapaScreen(
                    mantra: _selectedMantra,
                    targetBeads: _targetBeads > 0 ? _targetBeads : 108,
                    isCountBased: _targetBeads > 0,
                    totalMinutes: 15,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),
          const Text('Guided Meditation Practices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMeditationCard(
            title: 'Breath Awareness (Prana Dharana)',
            subtitle: 'Witness the spontaneous flow of breath without judgment.',
            icon: Icons.self_improvement,
            color: Colors.teal,
            duration: '10 min',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BreathAwarenessScreen(initialMinutes: 10),
                ),
              );
            },
          ),
          _buildMeditationCard(
            title: 'Yoga Nidra (Conscious Relaxation)',
            subtitle: 'Deep somatic relaxation and psychic rejuvenation before sleep.',
            icon: Icons.bedtime,
            color: Colors.indigo,
            duration: '20 min',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const YogaNidraScreen(durationMinutes: 20)),
              );
            },
          ),
          _buildMeditationCard(
            title: 'Trataka (Flame Gazing Dharana)',
            subtitle: 'Single-point gaze to calm thought waves and awaken concentration.',
            icon: Icons.visibility,
            color: Colors.purpleAccent,
            duration: '5 min',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Trataka concentration...')),
              );
            },
          ),
          _buildMeditationCard(
            title: 'Antar Mouna (Inner Silence)',
            subtitle: 'Pratyahara practice of witnessing thoughts with detachment.',
            icon: Icons.graphic_eq,
            color: Colors.deepOrange,
            duration: '15 min',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starting Antar Mouna practice...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String duration,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AbhyasTheme.darkSurface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(duration, style: const TextStyle(fontSize: 10, color: AbhyasTheme.darkInkSoft)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.play_arrow, color: AbhyasTheme.leaf, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
