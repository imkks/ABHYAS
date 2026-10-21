import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/session_repository.dart';
import '../../data/user_repository.dart';
import '../../engine/progression/progression_service.dart';
import '../path/path_map_screen.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../onboarding/health_screening_screen.dart';
import 'weaning_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressionService _progressionService = ProgressionService();
  final SessionRepository _sessionRepo = SessionRepository();
  final UserRepository _userRepo = UserRepository();

  UserProgression? _progression;
  int _tapasCount = 0;
  int _totalPracticeMinutes = 0;
  double _avgCalmnessDelta = 0.0;
  double _chtSeconds = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prog = await _progressionService.getProgression();
    final tapas = await _sessionRepo.getTapasCount();
    final totalMins = await _sessionRepo.getTotalPracticeMinutes();
    final delta = await _sessionRepo.getAverageCalmnessDelta();
    final benchmark = await _userRepo.loadChtBenchmark();
    final avgHold = await _sessionRepo.getAverageHold();

    if (mounted) {
      setState(() {
        _progression = prog;
        _tapasCount = tapas;
        _totalPracticeMinutes = totalMins;
        _avgCalmnessDelta = delta;
        _chtSeconds = benchmark ?? (avgHold > 0 ? avgHold : 20.0);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('My Journey (Mera)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading || _progression == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // 1. Current Level Rank & XP Card
                  _buildLevelCard(_progression!),

                  const SizedBox(height: 20),

                  // 2. "See The Difference" Metrics
                  const Text(
                    'Practice Metrics & Transformation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricTile('Tapas Count', '$_tapasCount', 'Sessions', Colors.deepOrange),
                      _buildMetricTile('Total Time', '$_totalPracticeMinutes', 'Minutes', Colors.amber),
                      _buildMetricTile('Calm Shift', _avgCalmnessDelta > 0 ? '+${(_avgCalmnessDelta * 10).round()}%' : '--', 'Post-practice', Colors.teal),
                      _buildMetricTile('CHT Hold', '${_chtSeconds.round()}s', 'Comfort test', Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 3. Sacred Seals Collection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mudra & Bandha Seals',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () async {
                          final profile = await _userRepo.loadProfile() ?? SafetyProfile();
                          if (!context.mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PathMapScreen(safetyProfile: profile)),
                          );
                          _loadStats();
                        },
                        child: const Text('Sopana Map', style: TextStyle(color: AbhyasTheme.saffron, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSeal('Gyan Mudra', _progression!.level >= 1),
                      _buildSeal('Chin Mudra', _progression!.level >= 1),
                      _buildSeal('Dhyana Mudra', _progression!.level >= 2),
                      _buildSeal('Nasika Mudra', _progression!.level >= 3),
                      _buildSeal('Jalandhara Bandha', _progression!.level >= 3),
                      _buildSeal('Shanmukhi Mudra', _progression!.level >= 4),
                      _buildSeal('Mula Bandha', _progression!.level >= 4),
                      _buildSeal('Uddiyana Bandha', _progression!.level >= 6),
                      _buildSeal('Maha Bandha', _progression!.level >= 6),
                      _buildSeal('Shambhavi Mudra', _progression!.level >= 7),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 4. Personal Preferences & Safety Profile
                  const Text(
                    'Preferences & Health Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: AbhyasTheme.darkSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AbhyasTheme.line)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.health_and_safety, color: AbhyasTheme.saffron),
                          title: const Text('Health Screening Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Review medical flags & practice advisories', style: TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HealthScreeningScreen(isUpdating: true)),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AbhyasTheme.line),
                        ListTile(
                          leading: const Icon(Icons.psychology, color: AbhyasTheme.leaf),
                          title: const Text('Guidance Level (Weaning)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Customize voice cues, bell sounds & haptics', style: TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => WeaningScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelCard(UserProgression prog) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AbhyasTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AbhyasTheme.saffron, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Level ${prog.level}: ${prog.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AbhyasTheme.saffron.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${prog.totalTapas} Tapas',
                  style: const TextStyle(color: AbhyasTheme.saffron, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Level Progress', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
              Text('${prog.currentLevelTapas} / ${prog.tapasNeededForNextLevel} to Level ${prog.level + 1}',
                  style: const TextStyle(color: AbhyasTheme.saffron, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prog.progressPercent,
              minHeight: 6,
              backgroundColor: AbhyasTheme.darkSurfaceAlt,
              color: AbhyasTheme.saffron,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Current Focus: ${prog.featureHighlight}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String sub, Color color) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AbhyasTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AbhyasTheme.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: AbhyasTheme.darkInkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeal(String name, bool earned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: earned ? AbhyasTheme.leaf.withValues(alpha: 0.15) : AbhyasTheme.darkSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: earned ? AbhyasTheme.leaf.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.verified : Icons.lock_outline,
            size: 13,
            color: earned ? AbhyasTheme.leaf : Colors.grey,
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: earned ? FontWeight.bold : FontWeight.normal,
              color: earned ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
