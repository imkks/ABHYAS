import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../engine/config/config_models.dart';
import '../../engine/config/seed_config.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../path/path_map_screen.dart';
import 'practice_player_screen.dart';

class PracticeListScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const PracticeListScreen({super.key, required this.safetyProfile});

  @override
  State<PracticeListScreen> createState() => _PracticeListScreenState();
}

class _PracticeListScreenState extends State<PracticeListScreen> {
  late PracticeConfig _config;

  @override
  void initState() {
    super.initState();
    _config = PracticeConfig.fromJson(seedConfig);
  }

  @override
  Widget build(BuildContext context) {
    final workflow = GuruAnumatiWorkflow();

    return Scaffold(
      appBar: AppBar(
        title: Text('Abhyas (Practices)'),
        actions: [
          IconButton(
            icon: Icon(Icons.alt_route, color: AbhyasTheme.saffron),
            tooltip: 'Sopana Path Roadmap',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PathMapScreen(safetyProfile: widget.safetyProfile),
                ),
              ).then((_) => setState(() {}));
            },
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner linking to Path
          Card(
            color: AbhyasTheme.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AbhyasTheme.saffron.withValues(alpha: 0.4)),
            ),
            child: ListTile(
              leading: Icon(Icons.alt_route, color: AbhyasTheme.saffron),
              title: Text('Sopana Path Roadmap', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('View the 7-level path to self-mastery'),
              trailing: Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PathMapScreen(safetyProfile: widget.safetyProfile),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
          ),
          SizedBox(height: 16),

          // Group practices by level
          ..._config.levels.map((level) {
            final isApproved = level.id <= 2 || workflow.isLevelApproved(level.id);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Text(
                        'Level ${level.id}: ${level.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isApproved ? AbhyasTheme.saffron : Colors.grey,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (!isApproved)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            level.gate.toUpperCase(),
                            style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                ...level.practices.map((practiceId) {
                  final bool allowedBySafety = SafetyRulesEngine.isPracticeAllowed(
                    practiceId,
                    widget.safetyProfile,
                    isApproved, // Teacher clearance passed if approved
                  );

                  final bool canPractice = isApproved && allowedBySafety;
                  final displayName = practiceId.replaceAll('_', ' ').toUpperCase();

                  String? reasonText;
                  if (!isApproved) {
                    reasonText = 'Requires Level ${level.id} unlock (${level.gate})';
                  } else if (!allowedBySafety) {
                    reasonText = 'Contraindicated by health screening';
                  }

                  return Card(
                    color: AbhyasTheme.darkSurface,
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        canPractice ? Icons.self_improvement : Icons.lock,
                        color: canPractice ? AbhyasTheme.leaf : Colors.grey,
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: canPractice ? Colors.white : Colors.white54,
                        ),
                      ),
                      subtitle: reasonText != null
                          ? Text(reasonText, style: TextStyle(color: Colors.orange, fontSize: 12))
                          : Text('Base ratio: ${level.ratioLadder.isNotEmpty ? level.ratioLadder.first.join(":") : "natural"}', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
                      trailing: canPractice
                          ? Icon(Icons.play_circle_fill, color: AbhyasTheme.saffron)
                          : Icon(Icons.lock, color: Colors.grey, size: 20),
                      onTap: canPractice
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PracticePlayerScreen(
                                    safetyProfile: widget.safetyProfile,
                                    practiceName: displayName,
                                    practiceId: practiceId,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                }),
                SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}
