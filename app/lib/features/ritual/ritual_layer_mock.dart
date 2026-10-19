import 'package:flutter/material.dart';
import 'astronomy_service.dart';
import 'pre_practice_ritual_screen.dart';
import 'mantra_library_screen.dart';

class RitualLayerMockScreen extends StatelessWidget {
  const RitualLayerMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final astro = AstronomyService(latitude: 28.6139, longitude: 77.2090); // New Delhi
    final now = DateTime.now();
    final brahmaMuhurta = astro.getBrahmaMuhurta(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Ritual Layer (Phase 3)')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_twilight, color: Colors.orange),
              title: const Text('Local Brahma Muhurta'),
              subtitle: Text('${brahmaMuhurta.hour.toString().padLeft(2, '0')}:${brahmaMuhurta.minute.toString().padLeft(2, '0')} AM'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.self_improvement),
            label: const Text('Start Pre-Practice Ritual'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PrePracticeRitualScreen(
                onComplete: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ritual Complete. Proceeding to practice...')));
                }
              )));
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text('View Mantra Library'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MantraLibraryScreen()));
            },
          ),
        ],
      ),
    );
  }
}
