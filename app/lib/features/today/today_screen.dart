import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../data/user_repository.dart';
import '../../data/session_repository.dart';
import '../practice/cycle_composer_screen.dart';
import '../dhyan/dhyan_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Aaj (Today)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTodayData,
            tooltip: 'Refresh',
          )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodayData,
              child: ListView(
                padding: EdgeInsets.all(24),
                children: [
                  Text(
                    'Namaste, Practitioner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AbhyasTheme.saffron,
                    ),
                  ),
                  Text(
                    'Sampradaya: $_tradition · Streak: $_comfortStreak days · Tapas: $_tapasCount',
                    style: TextStyle(color: AbhyasTheme.darkInkSoft),
                  ),
                  SizedBox(height: 30),

                  _buildMuhurtaCard(),
                  SizedBox(height: 16),
                  _buildSankalpCard(context),
                  SizedBox(height: 16),
                  _buildPracticeCard(context),
                  SizedBox(height: 16),
                  _buildMalaCard(),
                  SizedBox(height: 16),
                  _buildEveningCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildMuhurtaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_twilight, color: AbhyasTheme.sky),
                SizedBox(width: 8),
                Text('Brahma Muhurta', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('4:52 AM – 5:40 AM', style: TextStyle(fontSize: 18)),
            Text(
              'Sunrise: 6:28 AM · Local',
              style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSankalpCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.handshake, color: AbhyasTheme.clay),
        title: Text('"Today my intention is to practice steadiness."'),
        trailing: Icon(Icons.edit, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sankalp set for today\'s practice.')),
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
        side: BorderSide(color: AbhyasTheme.saffron, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Practice Cycle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AbhyasTheme.saffron,
              ),
            ),
            SizedBox(height: 8),
            Text('Full cycle · 30 min', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
            Text(
              'Kapalbhati → Nadi Shodhana → Ujjayi',
              style: TextStyle(color: AbhyasTheme.darkInkSoft),
            ),
            SizedBox(height: 20),
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
                    child: Text('Begin Cycle'),
                  ),
                ),
                SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CycleComposerScreen()),
                    );
                  },
                  child: Text('Adjust'),
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
        leading: Icon(Icons.spa, color: AbhyasTheme.saffron),
        title: Text('Mala Progress'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: _malaCount / 108.0,
              color: AbhyasTheme.saffron,
              backgroundColor: AbhyasTheme.darkSurfaceAlt,
            ),
            SizedBox(height: 4),
            Text('$_malaCount of 108 beads completed', style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
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
        title: Text('Evening Practice'),
        subtitle: Text('Yoga Nidra · 20 min'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade400),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DhyanScreen()),
            ).then((_) => _loadTodayData());
          },
          child: Text('Go to Dhyan'),
        ),
      ),
    );
  }
}
