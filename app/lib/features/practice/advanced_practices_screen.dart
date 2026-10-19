import 'package:flutter/material.dart';

class AdvancedPracticesScreen extends StatelessWidget {
  const AdvancedPracticesScreen({super.key});

  final List<String> _level6Practices = const ['Bahya Kumbhaka', 'Uddiyana Bandha', 'Maha Bandha'];
  final List<String> _level7Practices = const ['Trataka', 'Antar Mouna', 'Ajapa Japa'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Practices (Level 6-7)')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Level 6 (Bahya) Practices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ..._level6Practices.map((p) => ListTile(
            leading: const Icon(Icons.lock_open, color: Colors.orange),
            title: Text(p),
            subtitle: const Text('Requires Teacher Approval & Empty Stomach'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting $p player (Mock)')));
            },
          )),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Level 7 (Dhyana) Practices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ..._level7Practices.map((p) => ListTile(
            leading: const Icon(Icons.lock, color: Colors.red),
            title: Text(p),
            subtitle: const Text('Requires Guru Anumati'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locked. Request Guru Anumati in Progress Tab.')));
            },
          )),
        ],
      ),
    );
  }
}
