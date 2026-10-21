import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../engine/panchang/panchang_service.dart';
import '../../engine/progression/progression_service.dart';
import '../practice/cycle_composer_screen.dart';
import '../practice/breath_capacity_test_screen.dart';
import '../panchang/panchang_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final PanchangService _panchangService = PanchangService();
  final ProgressionService _progressionService = ProgressionService();

  String _tradition = 'Traditional';
  UserProgression? _progression;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final userRepo = UserRepository();
    final tradition = await userRepo.loadTradition();
    final prog = await _progressionService.getProgression();

    if (mounted) {
      setState(() {
        _tradition = tradition ?? 'Smarta';
        _progression = prog;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayPanchang = _panchangService.getTodayPanchang();
    final dateSubtitle =
        '${todayPanchang.vara.englishDay} · ${todayPanchang.tithi.name} (${todayPanchang.tithi.pakshaName})';

    return Scaffold(
      backgroundColor: AbhyasTheme.darkBg,
      appBar: AppBar(
        title: const Text('Sadhana (Today)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AbhyasTheme.saffron),
            tooltip: 'View Astronomical Panchang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanchangScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading || _progression == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // 1. Gamified Level & Tapas Progress Header
                  _buildGamifiedLevelCard(_progression!, dateSubtitle),

                  const SizedBox(height: 16),

                  // 2. Morning Routine Card (Surya Abhyas)
                  _buildMorningPracticeCard(context, _progression!),

                  const SizedBox(height: 14),

                  // 3. Bedtime Routine Card (Chandra Abhyas)
                  _buildEveningPracticeCard(context),

                  const SizedBox(height: 14),

                  // 4. Quick Duration Time Selector
                  _buildQuickTimeSelector(context),

                  const SizedBox(height: 14),

                  // 5. Daily Sankalp (Quiet single-line intention)
                  _buildSankalpCard(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildGamifiedLevelCard(UserProgression prog, String panchangDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF231F34),
            const Color(0xFF1B1829),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Level Title + Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, color: AbhyasTheme.saffron, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL ${prog.level}: ${prog.title.toUpperCase()}',
                        style: const TextStyle(
                          color: AbhyasTheme.saffron,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        panchangDate,
                        style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      '${prog.dailyStreak} Days',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tapas XP Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tapasya: ${prog.totalTapas} pts',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '${prog.currentLevelTapas} / ${prog.tapasNeededForNextLevel} to Level ${prog.level + 1}',
                style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 11),
              ),
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

          // Feature Highlight Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AbhyasTheme.darkSurfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: AbhyasTheme.saffron),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Unlocked: ${prog.featureHighlight}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BreathCapacityTestScreen()),
              ).then((_) => _loadTodayData());
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AbhyasTheme.saffron.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AbhyasTheme.saffron.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, size: 14, color: AbhyasTheme.saffron),
                  SizedBox(width: 6),
                  Text(
                    'Find My Apt Level (1-Min Breath Test)',
                    style: TextStyle(color: AbhyasTheme.saffron, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: AbhyasTheme.saffron),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorningPracticeCard(BuildContext context, UserProgression prog) {
    return Card(
      color: AbhyasTheme.saffron.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AbhyasTheme.saffron, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      '🌅 Morning Surya Abhyas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AbhyasTheme.saffron,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('30 min', style: TextStyle(color: AbhyasTheme.saffron, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '⚡ Level ${prog.level} Scaled: Kapalbhati (${prog.kapalbhatiStrokes}) → Nadi Shodhana (${prog.ratioDescription}) → Dhyan',
              style: const TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.black, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AbhyasTheme.saffron,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CycleComposerScreen(
                            initialPreset: RoutinePreset.surya,
                            initialDuration: 30,
                          ),
                        ),
                      ).then((_) => _loadTodayData());
                    },
                    label: const Text('Begin Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AbhyasTheme.line),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CycleComposerScreen(
                          initialPreset: RoutinePreset.surya,
                          initialDuration: 30,
                        ),
                      ),
                    ).then((_) => _loadTodayData());
                  },
                  child: const Text('Customize'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEveningPracticeCard(BuildContext context) {
    return Card(
      color: Colors.indigo.shade900.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.indigo.shade400, width: 1.2),
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
                    Icon(Icons.bedtime, color: Colors.indigo.shade300, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '🌙 Bedtime Chandra Abhyas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade200,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade800.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('25 min', style: TextStyle(color: Colors.indigo.shade200, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Naam Jaap (108 beads) → Bhramari → Guided Yoga Nidra for sleep',
              style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CycleComposerScreen(
                            initialPreset: RoutinePreset.chandra,
                            initialDuration: 25,
                          ),
                        ),
                      ).then((_) => _loadTodayData());
                    },
                    label: const Text('Begin Bedtime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AbhyasTheme.line),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CycleComposerScreen(
                          initialPreset: RoutinePreset.chandra,
                          initialDuration: 25,
                        ),
                      ),
                    ).then((_) => _loadTodayData());
                  },
                  child: const Text('Customize'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimeSelector(BuildContext context) {
    return Card(
      color: AbhyasTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.av_timer, color: AbhyasTheme.saffron, size: 16),
                SizedBox(width: 6),
                Text(
                  'Quick Practice: How much time do you have?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [10, 15, 20, 30, 45].map((mins) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CycleComposerScreen(
                          initialDuration: mins,
                        ),
                      ),
                    ).then((_) => _loadTodayData());
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.darkSurfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AbhyasTheme.line),
                    ),
                    child: Text(
                      '${mins}m',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSankalpCard(BuildContext context) {
    return Card(
      color: AbhyasTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      child: ListTile(
        leading: const Icon(Icons.handshake_outlined, color: AbhyasTheme.clay, size: 20),
        title: const Text(
          '"Today my intention is to practice steadiness of breath and mind."',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
        ),
      ),
    );
  }
}
