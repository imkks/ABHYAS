import 'package:flutter/material.dart';

class PrePracticeRitualScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PrePracticeRitualScreen({super.key, required this.onComplete});

  @override
  State<PrePracticeRitualScreen> createState() => _PrePracticeRitualScreenState();
}

class _PrePracticeRitualScreenState extends State<PrePracticeRitualScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _ritualSteps = [
    {
      'title': 'Achamana',
      'instruction': 'Take three sips of water. Purify the body and mind.'
    },
    {
      'title': 'Asana Sthapana',
      'instruction': 'Establish your seat. Ensure your spine is straight and posture is steady.'
    },
    {
      'title': 'Sankalp (Resolve)',
      'instruction': 'Set your intention for today\'s practice. Dedicate the effort.'
    },
    {
      'title': 'Invocation',
      'instruction': 'Om Sahana Vavatu. May we be protected together.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final step = _ritualSteps[_currentStep];
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Practice Ritual')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.self_improvement, size: 80, color: Colors.orangeAccent),
              const SizedBox(height: 32),
              Text(step['title']!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(step['instruction']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  if (_currentStep < _ritualSteps.length - 1) {
                    setState(() => _currentStep++);
                  } else {
                    widget.onComplete();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(_currentStep < _ritualSteps.length - 1 ? 'Next' : 'Begin Practice', style: const TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
