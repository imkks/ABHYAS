import 'package:flutter/material.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import '../../data/session_repository.dart';
import '../../data/user_repository.dart';
import '../dev/teacher_console_mock_screen.dart';
import '../path/path_map_screen.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../panchang/widgets/panchang_tithi_banner.dart';
import 'weaning_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final GuruAnumatiWorkflow _workflow = GuruAnumatiWorkflow();
  final SessionRepository _sessionRepo = SessionRepository();
  final UserRepository _userRepo = UserRepository();

  int _tapasCount = 0;
  int _totalPracticeMinutes = 0;
  double _avgCalmnessDelta = 0.0;
  double _chtSeconds = 0.0;
  int _currentLevel = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final tapas = await _sessionRepo.getTapasCount();
    final totalMins = await _sessionRepo.getTotalPracticeMinutes();
    final delta = await _sessionRepo.getAverageCalmnessDelta();
    final benchmark = await _userRepo.loadChtBenchmark();
    final avgHold = await _sessionRepo.getAverageHold();

    int level = 1;
    for (int l = 7; l >= 2; l--) {
      if (_workflow.isLevelApproved(l)) {
        level = l;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _tapasCount = tapas;
        _totalPracticeMinutes = totalMins;
        _avgCalmnessDelta = delta;
        _chtSeconds = benchmark ?? (avgHold > 0 ? avgHold : 20.0);
        _currentLevel = level;
        _loading = false;
      });
    }
  }

  void _requestUnlock(int level) {
    setState(() {
      _workflow.requestUnlock("practitioner-1", level);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unlock request sent to teacher for Level $level'))
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextLevel = _currentLevel + 1;
    final hasPendingRequest = _workflow.requests.any(
      (r) => r.requestedLevel == nextLevel && r.status == UnlockStatus.pending,
    );
    final isApproved = _workflow.isLevelApproved(nextLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherConsoleMockScreen(workflow: _workflow),
                ),
              );
              _loadStats();
            },
            tooltip: 'Teacher Console',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  PanchangTithiBanner(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.saffron.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: AbhyasTheme.saffron, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Self-Mastery Mode Active',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AbhyasTheme.saffron, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'All 7 Sopana levels are unlocked for personal practice & exploration.',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCircularStat('Tapas', '$_tapasCount', Colors.deepOrange),
                      _buildCircularStat('Minutes', '$_totalPracticeMinutes', Colors.amber),
                      _buildCircularStat('Calm Shift', _avgCalmnessDelta > 0 ? '+${(_avgCalmnessDelta * 10).round()}%' : '--', Colors.teal),
                      _buildCircularStat('CHT', '${_chtSeconds.toStringAsFixed(0)}s', Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.psychology),
                    label: const Text('Guidance Level (Weaning)'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WeaningScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Mudra & Bandha Seals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSeal('Gyan', _currentLevel >= 1),
                      _buildSeal('Chin', _currentLevel >= 1),
                      _buildSeal('Dhyana', _currentLevel >= 2),
                      _buildSeal('Nasika', _currentLevel >= 3),
                      _buildSeal('Jalandhara', _currentLevel >= 5),
                    ],
                  ),

                  const SizedBox(height: 40),
                  const Text(
                    'Guru Anumati',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (nextLevel <= 7)
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isApproved ? Colors.green : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Text(
                          'Sopana $nextLevel Progression',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isApproved
                              ? 'Approved for Practice'
                              : (hasPendingRequest
                                  ? 'Awaiting Teacher Review'
                                  : 'Tap to Request Unlock'),
                        ),
                        trailing: isApproved
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                            : (hasPendingRequest
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  )
                                : const Icon(Icons.lock, color: Colors.grey, size: 32)),
                        onTap: (!isApproved && !hasPendingRequest)
                            ? () => _requestUnlock(nextLevel)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCircularStat(String title, String value, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5), width: 4),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)
              ],
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildSeal(String name, bool earned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: earned ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: earned ? Colors.green : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.stars : Icons.lock_outline,
            size: 16,
            color: earned ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(color: earned ? Colors.white : Colors.grey)),
        ],
      ),
    );
  }
}
