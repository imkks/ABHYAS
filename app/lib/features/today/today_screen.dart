import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../data/session_repository.dart';
import '../../engine/panchang/panchang_service.dart';
import '../practice/cycle_composer_screen.dart';
import '../dhyan/dhyan_screen.dart';
import '../panchang/panchang_screen.dart';
import '../panchang/widgets/panchang_muhurta_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final PanchangService _panchangService = PanchangService();
  String _tradition = 'Traditional';
  int _tapasCount = 0;
  int _comfortStreak = 0;
  int _malaCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final userRepo = UserRepository();
    final sessionRepo = SessionRepository();
    final prefs = await SharedPreferences.getInstance();

    final tradition = await userRepo.loadTradition();
    final tapas = await sessionRepo.getTapasCount();
    final streak = await sessionRepo.getComfortStreak();
    final mala = prefs.getInt('daily_mala_count') ?? 0;

    if (mounted) {
      setState(() {
        _tradition = tradition ?? 'Smarta';
        _tapasCount = tapas;
        _comfortStreak = streak;
        _malaCount = mala;
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
      appBar: AppBar(
        title: const Text('Aaj (Today)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Panchang',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Namaste, Practitioner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AbhyasTheme.saffron,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateSubtitle,
                    style: const TextStyle(
                      color: AbhyasTheme.saffron,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Sampradaya: $_tradition · Streak: $_comfortStreak days · Tapas: $_tapasCount',
                    style: const TextStyle(color: AbhyasTheme.darkInkSoft),
                  ),
                  const SizedBox(height: 24),

                  PanchangMuhurtaCard(),
                  const SizedBox(height: 16),
                  _buildQuickTimeSelector(context),
                  const SizedBox(height: 16),
                  _buildSankalpCard(context),
                  const SizedBox(height: 16),
                  _buildMorningPracticeCard(context),
                  const SizedBox(height: 16),
                  _buildEveningPracticeCard(context),
                  const SizedBox(height: 16),
                  _buildMalaCard(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.av_timer, color: AbhyasTheme.saffron, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'How much time do you have today?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      child: ListTile(
        leading: const Icon(Icons.handshake, color: AbhyasTheme.clay),
        title: const Text('"Today my intention is to practice steadiness."'),
        trailing: const Icon(Icons.edit, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sankalp set for today\'s practice.')),
          );
        },
      ),
    );
  }

  Widget _buildMorningPracticeCard(BuildContext context) {
    return Card(
      color: AbhyasTheme.saffron.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AbhyasTheme.saffron, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🌅 Morning Surya Abhyas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AbhyasTheme.saffron,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AbhyasTheme.saffron.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('30 min', style: TextStyle(color: AbhyasTheme.saffron, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Kapalbhati → Nadi Shodhana → Ujjayi → Breath Awareness Dhyan',
              style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AbhyasTheme.saffron,
                      foregroundColor: Colors.black,
                      elevation: 2,
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
                      );
                    },
                    child: const Text('Begin Morning Routine', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AbhyasTheme.line),
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
                    );
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.indigo.shade400, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime, color: Colors.indigo.shade300, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '🌙 Bedtime Chandra Abhyas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade200,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade800.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('25 min', style: TextStyle(color: Colors.indigo.shade200, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Naam Jaap (108 beads) → Bhramari → Guided Yoga Nidra',
              style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      foregroundColor: Colors.white,
                      elevation: 2,
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
                      );
                    },
                    child: const Text('Begin Bedtime Routine', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AbhyasTheme.line),
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
                    );
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

  Widget _buildMalaCard() {
    return Card(
      color: AbhyasTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AbhyasTheme.line),
      ),
      child: ListTile(
        leading: const Icon(Icons.spa, color: AbhyasTheme.saffron),
        title: const Text('Mala Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (_malaCount / 108.0).clamp(0.0, 1.0),
              color: AbhyasTheme.saffron,
              backgroundColor: AbhyasTheme.darkSurfaceAlt,
            ),
            const SizedBox(height: 4),
            Text('$_malaCount of 108 beads completed', style: const TextStyle(fontSize: 12, color: AbhyasTheme.darkInkSoft)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DhyanScreen()),
          ).then((_) => _loadTodayData());
        },
      ),
    );
  }
}
