import 'package:flutter/material.dart';

class SessionComposerScreen extends StatefulWidget {
  const SessionComposerScreen({super.key});

  @override
  State<SessionComposerScreen> createState() => _SessionComposerScreenState();
}

class _SessionComposerScreenState extends State<SessionComposerScreen> {
  int _selectedDuration = 20;
  String _selectedPurpose = 'Balancing';
  String _selectedTimeOfDay = 'Morning';

  final List<int> _durations = [10, 20, 30, 45];
  final List<String> _purposes = ['Energizing', 'Balancing', 'Calming'];
  final List<String> _timesOfDay = ['Morning', 'Evening', 'Sleep'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compose Routine')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Time of Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _timesOfDay.map((time) {
                return ChoiceChip(
                  label: Text(time),
                  selected: _selectedTimeOfDay == time,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedTimeOfDay = time);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Duration (minutes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations.map((duration) {
                return ChoiceChip(
                  label: Text('$duration min'),
                  selected: _selectedDuration == duration,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDuration = duration);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Purpose', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _purposes.map((purpose) {
                return ChoiceChip(
                  label: Text(purpose),
                  selected: _selectedPurpose == purpose,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedPurpose = purpose);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Generate and navigate to generated circuit
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generating $_selectedDuration min $_selectedTimeOfDay $_selectedPurpose Routine...'))
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Generate & Start Practice', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
