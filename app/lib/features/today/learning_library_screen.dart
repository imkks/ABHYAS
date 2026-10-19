import 'package:flutter/material.dart';

class LearningLibraryScreen extends StatelessWidget {
  const LearningLibraryScreen({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {
      'title': 'Pranayama Fundamentals',
      'items': ['Ujjayi', 'Bhramari', 'Nadi Shodhana Basic']
    },
    {
      'title': 'Advanced Pranayama',
      'items': ['Kapalbhati', 'Bhastrika', 'Kumbhaka Intro']
    },
    {
      'title': 'Mudras & Bandhas',
      'items': ['Gyan Mudra', 'Nasika Mudra', 'Jalandhara Bandha']
    },
    {
      'title': 'Dhyan (Meditation)',
      'items': ['Breath Awareness', 'Mental Om', 'Trataka']
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Library')),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ExpansionTile(
            title: Text(category['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            children: (category['items'] as List<String>).map((item) {
              return ListTile(
                title: Text(item),
                trailing: const Icon(Icons.play_arrow, color: Colors.deepOrange),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Starting individual practice: $item'))
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
