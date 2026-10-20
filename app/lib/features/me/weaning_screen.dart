import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../practice/self_check_practice_screen.dart';

class WeaningScreen extends StatefulWidget {
  const WeaningScreen({super.key});

  @override
  State<WeaningScreen> createState() => _WeaningScreenState();
}

class _WeaningScreenState extends State<WeaningScreen> {
  int _currentStage = 1;
  int _comfortStreak = 0;
  bool _loading = true;

  final List<Map<String, String>> _stages = [
    {'id': '1', 'name': 'Guided', 'desc': 'Visuals, Voice cues, Haptics, Counts'},
    {'id': '2', 'name': 'Cued', 'desc': 'Phase change chime only, Haptics'},
    {'id': '3', 'name': 'Silent Timer', 'desc': 'No audio cues, Per-round haptic pulse'},
    {'id': '4', 'name': 'Self-led', 'desc': 'Start/End bell only. No screen pacer.'},
    {'id': '5', 'name': 'Independent', 'desc': 'Self-check practice mode with internal counting.'},
  ];

  @override
  void initState() {
    super.initState();
    _loadWeaningData();
  }

  Future<void> _loadWeaningData() async {
    final repo = SessionRepository();
    final streak = await repo.getComfortStreak();

    // Stage progression logic: 10 calm sessions per stage advancement
    int calculatedStage = 1 + (streak ~/ 10);
    if (calculatedStage > 5) calculatedStage = 5;

    if (mounted) {
      setState(() {
        _comfortStreak = streak;
        _currentStage = calculatedStage;
        _loading = false;
      });
    }
  }

  void _showLessonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AbhyasTheme.darkSurface,
        title: Text('Traditional Counting Methods', style: TextStyle(color: AbhyasTheme.saffron)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Matra / Heartbeat Sync',
                style: TextStyle(fontWeight: FontWeight.bold, color: AbhyasTheme.sky),
              ),
              SizedBox(height: 4),
              Text(
                'One Matra is traditionally measured as the duration of one normal heartbeat (~1 second) or snapping fingers around the knee.',
                style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '2. Finger Phalanx Counting (Kara Mala)',
                style: TextStyle(fontWeight: FontWeight.bold, color: AbhyasTheme.sky),
              ),
              SizedBox(height: 4),
              Text(
                'Use the thumb to touch the 12 phalanges of the fingers of the right hand in a clockwise loop to keep count without visual distraction.',
                style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '3. Mental Mantra Pulse',
                style: TextStyle(fontWeight: FontWeight.bold, color: AbhyasTheme.sky),
              ),
              SizedBox(height: 4),
              Text(
                'Repeat mental syllables (e.g. Om 1, Om 2, Om 3...) steadily to develop effortless internal rhythm.',
                style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Understood', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streakInCurrentStage = _comfortStreak % 10;
    final progressToNext = streakInCurrentStage / 10.0;

    return Scaffold(
      appBar: AppBar(title: Text('Guidance Level (Weaning)')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(24),
              children: [
                Text(
                  'Practicing without the app',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AbhyasTheme.saffron,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Stage $_currentStage of 5 · ${_stages[_currentStage - 1]['name']}',
                  style: TextStyle(fontSize: 16, color: AbhyasTheme.darkInkSoft),
                ),
                SizedBox(height: 30),

                // Stepper indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    int stageNum = index + 1;
                    bool isActive = stageNum <= _currentStage;
                    bool isCurrent = stageNum == _currentStage;

                    return Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? AbhyasTheme.saffron
                                  : (isActive ? AbhyasTheme.sky : AbhyasTheme.darkSurfaceAlt),
                              border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: Center(
                              child: Text(
                                stageNum.toString(),
                                style: TextStyle(
                                  color: isActive ? AbhyasTheme.darkBg : AbhyasTheme.darkInkSoft,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          if (index < 4)
                            Expanded(
                              child: Container(
                                height: 4,
                                color: isActive ? AbhyasTheme.sky : AbhyasTheme.darkSurfaceAlt,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),

                SizedBox(height: 40),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStage < 5
                              ? 'Progress to Stage ${_currentStage + 1}'
                              : 'Stage 5 Mastery',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _currentStage < 5
                              ? 'You have completed $streakInCurrentStage of 10 consecutive comfortable sessions in this stage.'
                              : 'You have attained independent practice mastery.',
                          style: TextStyle(color: AbhyasTheme.darkInkSoft),
                        ),
                        SizedBox(height: 15),
                        LinearProgressIndicator(
                          value: _currentStage < 5 ? progressToNext : 1.0,
                          backgroundColor: AbhyasTheme.darkSurfaceAlt,
                          color: AbhyasTheme.leaf,
                        )
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),
                Text('Actions & Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ListTile(
                  tileColor: AbhyasTheme.darkSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(Icons.menu_book, color: AbhyasTheme.saffron),
                  title: Text('Counting Method Lesson'),
                  subtitle: Text('Finger and mental pacing'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showLessonDialog,
                ),
                SizedBox(height: 10),
                ListTile(
                  tileColor: AbhyasTheme.darkSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(Icons.timer, color: AbhyasTheme.sky),
                  title: Text('Self-Check Practice'),
                  subtitle: Text('Benchmark internal rhythm'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelfCheckPracticeScreen()),
                    ).then((_) => _loadWeaningData());
                  },
                ),

                SizedBox(height: 40),
                Divider(color: AbhyasTheme.line),
                SizedBox(height: 20),
                Text('Testing Overrides (Dev Only)', style: TextStyle(color: Colors.grey)),
                DropdownButton<int>(
                  value: _currentStage,
                  dropdownColor: AbhyasTheme.darkSurfaceAlt,
                  items: [1, 2, 3, 4, 5].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('Force Stage $value: ${_stages[value - 1]['name']}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _currentStage = val!;
                    });
                  },
                )
              ],
            ),
    );
  }
}
