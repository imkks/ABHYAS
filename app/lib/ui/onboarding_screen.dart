import 'package:flutter/material.dart';
import 'health_screening_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _consentGiven = false;
  String _selectedTradition = 'Smarta';
  final List<String> _traditions = ['Smarta', 'Vaishnava', 'Shaiva', 'Shakta', 'Arya Samaj', 'Other'];

  void _proceed() {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please provide explicit consent to proceed.'),
      ));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HealthScreeningScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Abhyas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilot Program Consent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'This is a closed-circle pilot. All practices are traditional and should be guided by a teacher. This is not medical advice. Consult your physician before beginning any practice.',
            ),
            CheckboxListTile(
              title: Text('I explicitly consent to participate and acknowledge the privacy terms.'),
              value: _consentGiven,
              onChanged: (val) => setState(() => _consentGiven = val ?? false),
            ),
            SizedBox(height: 20),
            Text(
              'Select Tradition (Sampradaya):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedTradition,
              isExpanded: true,
              items: _traditions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTradition = newValue!;
                });
              },
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _proceed,
                child: Text('Next: Health Screening'),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
