import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../engine/panchang/panchang_service.dart';
import '../panchang_screen.dart';

/// Dynamic Panchang Tithi & Muhurta banner used on the Progress and Me screens.
class PanchangTithiBanner extends StatelessWidget {
  final PanchangService _panchangService = PanchangService();

  PanchangTithiBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final panchang = _panchangService.getTodayPanchang();
    final brahmaStatus = _panchangService.getBrahmaMuhurtaStatus(now);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PanchangScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900,
              Colors.indigo.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.deepPurple.shade700,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_sunny, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        brahmaStatus.isActive
                            ? 'Brahma Muhurta Active!'
                            : 'Brahma Muhurta ${brahmaStatus.countdownString}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Panchang: ${panchang.tithi.name} (${panchang.tithi.pakshaName}) · ${panchang.nakshatra.name}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
