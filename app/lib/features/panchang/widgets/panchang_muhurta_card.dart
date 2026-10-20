import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../engine/panchang/panchang_service.dart';
import '../../../engine/panchang/panchang_models.dart';
import '../panchang_screen.dart';

/// Interactive Muhurta Card for Today screen, dynamically calculating
/// real-time Brahma Muhurta, Sunrise, Sunset, and Tithi.
class PanchangMuhurtaCard extends StatelessWidget {
  final PanchangService _panchangService = PanchangService();

  PanchangMuhurtaCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final panchang = _panchangService.getTodayPanchang();
    final brahmaStatus = _panchangService.getBrahmaMuhurtaStatus(now);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: brahmaStatus.isActive
              ? AbhyasTheme.saffron
              : AbhyasTheme.line,
          width: brahmaStatus.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: brahmaStatus.isActive
                            ? AbhyasTheme.saffron.withOpacity(0.2)
                            : AbhyasTheme.sky.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.wb_twilight,
                        color: brahmaStatus.isActive
                            ? AbhyasTheme.saffron
                            : AbhyasTheme.sky,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Brahma Muhurta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          brahmaStatus.isActive
                              ? 'Active Window Now'
                              : 'Next Dawn Window',
                          style: TextStyle(
                            color: brahmaStatus.isActive
                                ? AbhyasTheme.saffron
                                : AbhyasTheme.darkInkSoft,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brahmaStatus.isActive
                        ? AbhyasTheme.saffron
                        : AbhyasTheme.darkSurfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    brahmaStatus.countdownString,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: brahmaStatus.isActive
                          ? AbhyasTheme.darkBg
                          : AbhyasTheme.darkInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${PanchangService.formatTime(panchang.brahmaMuhurta.startTime)} – ${PanchangService.formatTime(panchang.brahmaMuhurta.endTime)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 14, color: AbhyasTheme.saffron),
                const SizedBox(width: 4),
                Text(
                  'Sunrise: ${PanchangService.formatTime(panchang.sunrise)}',
                  style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Icon(Icons.nightlight_outlined, size: 14, color: AbhyasTheme.sky),
                const SizedBox(width: 4),
                Text(
                  'Sunset: ${PanchangService.formatTime(panchang.sunset)}',
                  style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24, color: AbhyasTheme.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${panchang.tithi.name} · ${panchang.nakshatra.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AbhyasTheme.darkInk,
                        ),
                      ),
                      Text(
                        '${panchang.location.name} · ${panchang.tithi.pakshaName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AbhyasTheme.darkInkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PanchangScreen()),
                    );
                  },
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Full Panchang'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AbhyasTheme.saffron,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
