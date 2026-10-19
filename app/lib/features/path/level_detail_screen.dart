import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'unlock_request_screen.dart';

class LevelDetailScreen extends StatelessWidget {
  final int levelId;
  final String name;
  final String gate;
  final bool isComplete;
  final bool isCurrent;

  const LevelDetailScreen({
    Key? key,
    required this.levelId,
    required this.name,
    required this.gate,
    required this.isComplete,
    required this.isCurrent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $levelId: $name')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details about $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Gate: $gate'),
            const SizedBox(height: 20),
            if (!isComplete && gate == 'teacher' && !isCurrent)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UnlockRequestScreen(levelId: levelId, levelName: name)
                  ));
                },
                child: const Text('Request Guru Anumati'),
              )
            else if (!isComplete && gate == 'guru_only')
              const Text('Learn about this level (Guru Only)', style: TextStyle(color: Colors.grey))
            else if (isCurrent || isComplete)
              ElevatedButton(
                onPressed: () {
                  // Begin level logic
                },
                child: const Text('Begin this level'),
              )
          ],
        ),
      ),
    );
  }
}
