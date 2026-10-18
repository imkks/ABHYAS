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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Center(
                  child: Icon(Icons.self_improvement, size: 80, color: Colors.deepOrange),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'ABHYAS',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                  ),
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilot Program Consent',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'This is a closed-circle pilot. All practices are traditional and should be guided by a teacher. This is not medical advice. Consult your physician before beginning any practice.',
                          style: TextStyle(color: Colors.grey.shade400, height: 1.5),
                        ),
                        SizedBox(height: 15),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.deepOrange,
                          title: Text('I explicitly consent to participate and acknowledge the privacy terms.', style: TextStyle(fontSize: 14)),
                          value: _consentGiven,
                          onChanged: (val) => setState(() => _consentGiven = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTradition,
                        isExpanded: true,
                        dropdownColor: Color(0xFF2C2C2C),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.deepOrange),
                        items: _traditions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text('Sampradaya: $value', style: TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTradition = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Next: Health Screening', style: TextStyle(fontSize: 18)),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
