import 'package:flutter/material.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import 'practice_player_screen.dart';

class PracticeListScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const PracticeListScreen({Key? key, required this.safetyProfile}) : super(key: key);

  @override
  _PracticeListScreenState createState() => _PracticeListScreenState();
}

class _PracticeListScreenState extends State<PracticeListScreen> {
  bool _level3Approved = false;
  bool _level4Approved = false;
  bool _level5Approved = false;

  final GuruAnumatiWorkflow _workflow = GuruAnumatiWorkflow();

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  void _loadApprovals() async {
    final l3 = await _workflow.isLevelApproved(3);
    final l4 = await _workflow.isLevelApproved(4);
    final l5 = await _workflow.isLevelApproved(5);

    if (mounted) {
      setState(() {
        _level3Approved = l3;
        _level4Approved = l4;
        _level5Approved = l5;
      });
    }
  }

  List<Map<String, dynamic>> get practices => [
    {'id': 'breath_awareness', 'name': 'Breath Awareness (Level 1)', 'level': 1},
    {'id': 'om_chant', 'name': 'Om Chanting (Level 1)', 'level': 1},
    {'id': 'bhramari', 'name': 'Bhramari (Level 1)', 'level': 1},
    {'id': 'nadi_shodhana', 'name': 'Nadi Shodhana Basic (Level 1)', 'level': 1},
    {'id': 'kapalbhati', 'name': 'Kapalbhati (Level 2)', 'level': 2},
    {'id': 'ujjayi', 'name': 'Ujjayi (Level 2)', 'level': 2},
    {'id': 'sheetali', 'name': 'Sheetali (Level 3)', 'level': 3},
    {'id': 'sheetkari', 'name': 'Sheetkari (Level 3)', 'level': 3},
    {'id': 'antar_kumbhaka_short', 'name': 'Antar Kumbhaka (Level 3)', 'level': 3},
    {'id': 'bhastrika', 'name': 'Bhastrika (Level 4)', 'level': 4},
    {'id': 'surya_bhedana', 'name': 'Surya Bhedana (Level 4)', 'level': 4},
    {'id': 'nadi_shodhana_full', 'name': 'Nadi Shodhana Full (Level 5)', 'level': 5},
  ];

  bool _isLevelApproved(int level) {
    if (level < 3) return true;
    if (level == 3) return _level3Approved;
    if (level == 4) return _level4Approved;
    if (level == 5) return _level5Approved;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sopanas (Levels 1-5)')),
      body: ListView.builder(
        itemCount: practices.length,
        itemBuilder: (context, index) {
          final practice = practices[index];
          final int level = practice['level'];
          final bool isApproved = _isLevelApproved(level);
          final bool safetyAllowed = SafetyRulesEngine.isPracticeAllowed(
            practice['id'],
            widget.safetyProfile,
            false // No teacher clearance in offline basic test
          );

          final bool canPlay = isApproved && safetyAllowed;

          String lockReason = '';
          if (!safetyAllowed) {
            lockReason = 'Locked: Consult doctor/teacher';
          } else if (!isApproved) {
            lockReason = 'Locked: Requires Teacher Approval (Level $level)';
          }

          return ListTile(
            title: Text(practice['name']),
            subtitle: canPlay ? null : Text(lockReason, style: const TextStyle(color: Colors.red)),
            trailing: canPlay ? const Icon(Icons.play_arrow) : const Icon(Icons.lock, color: Colors.red),
            onTap: canPlay ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PracticePlayerScreen(
                    safetyProfile: widget.safetyProfile,
                    practiceName: practice['name'],
                    practiceId: practice['id'],
                  ),
                ),
              );
            } : null,
          );
        },
      ),
    );
  }
}
