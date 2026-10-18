import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../practice/self_check_practice_screen.dart';

class WeaningScreen extends StatefulWidget {
  @override
  _WeaningScreenState createState() => _WeaningScreenState();
}

class _WeaningScreenState extends State<WeaningScreen> {
  int _currentStage = 3; // Defaulting to 3 for mockup purposes

  final List<Map<String, String>> _stages = [
    {'id': '1', 'name': 'Guided', 'desc': 'Visuals, Voice cues, Haptics, Counts'},
    {'id': '2', 'name': 'Cued', 'desc': 'Phase change voice only, Haptics'},
    {'id': '3', 'name': 'Silent Timer', 'desc': 'No voice, Per-round haptic pulse'},
    {'id': '4', 'name': 'Self-led', 'desc': 'Start/End bell only. No screen cues.'},
    {'id': '5', 'name': 'Independent', 'desc': 'Self-check practice mode.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guidance Level (Weaning)')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(
            'Practicing without the app',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AbhyasTheme.saffron),
          ),
          SizedBox(height: 10),
          Text(
            'Stage ${_currentStage} of 5 · ${_stages[_currentStage - 1]['name']}',
            style: TextStyle(fontSize: 16, color: AbhyasTheme.darkInkSoft),
          ),
          SizedBox(height: 30),

          // Custom Timeline/Stepper indicator
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
                        color: isCurrent ? AbhyasTheme.saffron : (isActive ? AbhyasTheme.sky : AbhyasTheme.darkSurfaceAlt),
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          stageNum.toString(),
                          style: TextStyle(color: isActive ? AbhyasTheme.darkBg : AbhyasTheme.darkInkSoft, fontWeight: FontWeight.bold, fontSize: 12),
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
                  Text('Progress to Stage ${_currentStage < 5 ? _currentStage + 1 : 5}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 10),
                  Text('You have completed 7 of 10 consecutive comfortable sessions needed to advance.', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: 0.7,
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
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening lesson placeholder...')));
            },
          ),
          SizedBox(height: 10),
          ListTile(
            tileColor: AbhyasTheme.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(Icons.timer, color: AbhyasTheme.sky),
            title: Text('Self-Check Practice'),
            subtitle: Text('Available in Stage 5'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SelfCheckPracticeScreen()));
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
                child: Text('Force Stage $value'),
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
