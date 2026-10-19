import 'package:flutter/material.dart';

class MantraLibraryScreen extends StatelessWidget {
  const MantraLibraryScreen({super.key});

  final List<Map<String, String>> _mantras = const [
    {
      'title': 'Om Chanting',
      'devanagari': 'ॐ',
      'meaning': 'The primordial sound of the universe.',
    },
    {
      'title': 'Gayatri Mantra',
      'devanagari': 'ॐ भूर्भुवः स्वः\nतत्सवितुर्वरेण्यं\nभर्गो देवस्य धीमहि\nधियो यो नः प्रचोदयात्॥',
      'meaning': 'May we meditate on the glory of that Being who has produced this universe; may He enlighten our minds.',
    },
    {
      'title': 'Patanjali Invocation',
      'devanagari': 'योगेन चित्तस्य पदेन वाचां\nमलं शरीरस्य च वैद्यकेन।\nयोऽपाकरोत्तं प्रवरं मुनीनां\nपतञ्जलिं प्राञ्जलिरानतोऽस्मि॥',
      'meaning': 'I bow with folded hands to Patanjali, the greatest of sages, who removed the impurity of mind through Yoga, of speech through grammar, and of the body through medicine.',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mantra & Invocation Library')),
      body: ListView.builder(
        itemCount: _mantras.length,
        itemBuilder: (context, index) {
          final mantra = _mantras[index];
          return Card(
            margin: const EdgeInsets.all(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mantra['title']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                  const SizedBox(height: 12),
                  Text(mantra['devanagari']!, style: const TextStyle(fontSize: 22, height: 1.5), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(mantra['meaning']!, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
