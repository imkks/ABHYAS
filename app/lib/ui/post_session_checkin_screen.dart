import 'package:flutter/material.dart';
import 'practice_list_screen.dart';
import '../safety/safety_rules_engine.dart';

class PostSessionCheckinScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;

  PostSessionCheckinScreen({required this.safetyProfile});

  @override
  _PostSessionCheckinScreenState createState() => _PostSessionCheckinScreenState();
}

class _PostSessionCheckinScreenState extends State<PostSessionCheckinScreen> {
  String _feeling = 'calm';
  bool _dizziness = false;
  final TextEditingController _noteController = TextEditingController();

  void _submit() {
    // In Phase 2, this will save to DB and trigger auto-regression logic if strained.

    // Return to list screen, popping everything else
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => PracticeListScreen(safetyProfile: widget.safetyProfile)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post-Session Check-in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _feeling,
              isExpanded: true,
              items: ['calm', 'neutral', 'agitated', 'strained'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _feeling = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            CheckboxListTile(
              title: Text('Did you feel dizziness?'),
              value: _dizziness,
              onChanged: (val) => setState(() => _dizziness = val ?? false),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Optional Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                child: Text('Done'),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
