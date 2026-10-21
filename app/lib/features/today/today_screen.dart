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
                  _buildSankalpCard(context),
                  const SizedBox(height: 16),
                  _buildPracticeCard(context),
                  const SizedBox(height: 16),
                  _buildMalaCard(),
                  const SizedBox(height: 16),
                  _buildEveningCard(context),
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

  Widget _buildPracticeCard(BuildContext context) {
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
            const Text(
              'Today\'s Practice Cycle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AbhyasTheme.saffron,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Full cycle · 30 min', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
            const Text(
              'Kapalbhati → Nadi Shodhana → Ujjayi',
              style: TextStyle(color: AbhyasTheme.darkInkSoft),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CycleComposerScreen()),
                      );
                    },
                    child: const Text('Begin Cycle'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CycleComposerScreen()),
                    );
                  },
                  child: const Text('Adjust'),
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
      child: ListTile(
        leading: const Icon(Icons.spa, color: AbhyasTheme.saffron),
        title: const Text('Mala Progress'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _malaCount / 108.0,
              color: AbhyasTheme.saffron,
              backgroundColor: AbhyasTheme.darkSurfaceAlt,
            ),
            const SizedBox(height: 4),
            Text('$_malaCount of 108 beads completed', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DhyanScreen()),
          ).then((_) => _loadTodayData());
        },
      ),
    );
  }

  Widget _buildEveningCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.bedtime, color: Colors.indigo.shade300),
        title: const Text('Evening Practice'),
        subtitle: const Text('Yoga Nidra · 20 min'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade400),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DhyanScreen()),
            ).then((_) => _loadTodayData());
          },
          child: const Text('Go to Dhyan'),
        ),
      ),
    );
  }
}
