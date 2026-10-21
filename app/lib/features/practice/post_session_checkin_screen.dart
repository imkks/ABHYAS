import 'package:flutter/material.dart';
import '../../core/main_layout.dart';
import '../../core/theme.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../../data/local_storage_service.dart';
import '../../data/session_repository.dart';

class PostSessionCheckinScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;
  final String practiceName;
  final int level;
  final int durationSeconds;
  final List<double> holdDurations;

  const PostSessionCheckinScreen({
    super.key,
    required this.safetyProfile,
    this.practiceName = 'Pranayama Practice',
    this.level = 1,
    this.durationSeconds = 300,
    this.holdDurations = const [],
  });

  @override
  State<PostSessionCheckinScreen> createState() => _PostSessionCheckinScreenState();
}

class _PostSessionCheckinScreenState extends State<PostSessionCheckinScreen> {
  String _feeling = 'calm';
  double _preCalmness = 4.0;
  double _postCalmness = 8.0;
  bool _dizziness = false;
  final Set<String> _selectedSensations = {'Mental clarity', 'Inner silence'};
  final TextEditingController _noteController = TextEditingController();

  final List<String> _availableSensations = [
    'Inner silence',
    'Mental clarity',
    'Steady warmth',
    'Lightness in chest',
    'Grounded calm',
    'Spiritual joy',
    'Vital energy',
  ];

  int get _deltaScore => (_postCalmness - _preCalmness).round();

  void _submit() async {
    final storage = LocalStorageService();
    await storage.saveCheckin({
      'timestamp': DateTime.now().toIso8601String(),
      'practiceName': widget.practiceName,
      'durationSeconds': widget.durationSeconds,
      'feeling': _feeling,
      'preCalmness': _preCalmness.round(),
      'postCalmness': _postCalmness.round(),
      'delta': _deltaScore,
      'dizziness': _dizziness,
      'sensations': _selectedSensations.toList(),
      'note': _noteController.text,
    });

    final sessionRepo = SessionRepository();
    await sessionRepo.logSession(SessionRecord(
      practiceName: widget.practiceName,
      level: widget.level,
      durationSeconds: widget.durationSeconds,
      timestamp: DateTime.now(),
      checkinRating: _feeling,
      holdDurations: widget.holdDurations,
      calmnessScore: _postCalmness.round(),
      preCalmnessScore: _preCalmness.round(),
      sensations: _selectedSensations.toList(),
    ));

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainLayout(safetyProfile: widget.safetyProfile)),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Post-Practice Reflection'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Completed Practice Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AbhyasTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AbhyasTheme.saffron.withValues(alpha: 0.2),
                  child: const Icon(Icons.check, color: AbhyasTheme.saffron),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.practiceName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Completed · ${(widget.durationSeconds / 60).round()} minutes',
                        style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Calmness Delta Section ("See the Difference")
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AbhyasTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AbhyasTheme.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calmness Shift (See The Difference)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _deltaScore >= 0 ? AbhyasTheme.leaf.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _deltaScore >= 0 ? AbhyasTheme.leaf : Colors.orange),
                      ),
                      child: Text(
                        _deltaScore >= 0 ? '+${_deltaScore * 10}% Calmer' : '$_deltaScore Change',
                        style: TextStyle(
                          color: _deltaScore >= 0 ? AbhyasTheme.leaf : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Before Practice Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Before Practice:', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
                    Text('${_preCalmness.round()} / 10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: _preCalmness,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.grey,
                  inactiveColor: AbhyasTheme.darkSurfaceAlt,
                  onChanged: (val) => setState(() => _preCalmness = val),
                ),

                const SizedBox(height: 8),

                // After Practice Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Now (Post-Practice):', style: TextStyle(color: AbhyasTheme.saffron, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${_postCalmness.round()} / 10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AbhyasTheme.saffron)),
                  ],
                ),
                Slider(
                  value: _postCalmness,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: AbhyasTheme.saffron,
                  inactiveColor: AbhyasTheme.darkSurfaceAlt,
                  onChanged: (val) => setState(() => _postCalmness = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Primary Feeling Dropdown
          const Text('Overall State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _feeling,
            decoration: InputDecoration(
              filled: true,
              fillColor: AbhyasTheme.darkSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AbhyasTheme.line)),
            ),
            items: const [
              DropdownMenuItem(value: 'calm', child: Text('Calm & Centered (Prasanna)')),
              DropdownMenuItem(value: 'neutral', child: Text('Steady & Balanced (Sama)')),
              DropdownMenuItem(value: 'agitated', child: Text('Restless / Distracted (Vikshipta)')),
              DropdownMenuItem(value: 'strained', child: Text('Strained / Fatigued (Ayasa)')),
            ],
            onChanged: (val) => setState(() => _feeling = val ?? 'calm'),
          ),

          const SizedBox(height: 20),

          // Physical Sensations Checklist
          const Text('Physical & Energetic Sensations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSensations.map((s) {
              final isSelected = _selectedSensations.contains(s);
              return FilterChip(
                label: Text(s),
                selected: isSelected,
                selectedColor: AbhyasTheme.saffron.withValues(alpha: 0.25),
                backgroundColor: AbhyasTheme.darkSurface,
                checkmarkColor: AbhyasTheme.saffron,
                labelStyle: TextStyle(
                  color: isSelected ? AbhyasTheme.saffron : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSensations.add(s);
                    } else {
                      _selectedSensations.remove(s);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Dizziness Flag
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Did you experience any dizziness or shortness of breath?', style: TextStyle(fontSize: 13)),
            value: _dizziness,
            activeColor: Colors.deepOrange,
            onChanged: (val) => setState(() => _dizziness = val ?? false),
          ),
          if (_dizziness) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Safety Note: If dizziness occurred, next session will automatically suggest shorter holds and more natural breathing periods.',
                style: TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // Journal Note
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Practice Journal (Optional reflection)',
              hintText: 'Note subtle experiences, breath ease, or inner states...',
              filled: true,
              fillColor: AbhyasTheme.darkSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 28),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AbhyasTheme.saffron,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submit,
            child: const Text('Save Reflection & Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
