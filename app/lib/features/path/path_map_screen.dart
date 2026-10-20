import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../engine/config/config_models.dart';
import '../../engine/config/seed_config.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import '../../engine/safety/safety_rules_engine.dart';
import 'level_detail_screen.dart';

class PathMapScreen extends StatefulWidget {
  final SafetyProfile safetyProfile;

  const PathMapScreen({super.key, required this.safetyProfile});

  @override
  State<PathMapScreen> createState() => _PathMapScreenState();
}

class _PathMapScreenState extends State<PathMapScreen> {
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
        title: Text('Sopana Path (Progression)'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Text(
            'The Seven Steps of Sadhana',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AbhyasTheme.saffron,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'From foundational breath awareness to advanced internal absorption.',
            style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
          ),
          SizedBox(height: 24),

          // Vertical timeline of the 7 levels
          ..._config.levels.map((level) {
            final isFirstTwo = level.id <= 2;
            final isApproved = isFirstTwo || workflow.isLevelApproved(level.id);
            final hasPending = workflow.requests.any(
              (r) => r.requestedLevel == level.id && r.status == UnlockStatus.pending,
            );

            return _buildTimelineNode(
              level: level,
              isApproved: isApproved,
              hasPending: hasPending,
              isLast: level.id == _config.levels.last.id,
            );
          }),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required SopanaLevel level,
    required bool isApproved,
    required bool hasPending,
    required bool isLast,
  }) {
    Color nodeColor;
    IconData nodeIcon;

    if (isApproved) {
      nodeColor = AbhyasTheme.leaf;
      nodeIcon = Icons.check;
    } else if (hasPending) {
      nodeColor = Colors.orange;
      nodeIcon = Icons.hourglass_top;
    } else {
      nodeColor = AbhyasTheme.line;
      nodeIcon = Icons.lock_outline;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isApproved ? nodeColor.withValues(alpha: 0.2) : AbhyasTheme.darkSurface,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Center(
                  child: Icon(nodeIcon, size: 18, color: nodeColor),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isApproved ? AbhyasTheme.leaf.withValues(alpha: 0.5) : AbhyasTheme.line,
                  ),
                ),
            ],
          ),
          SizedBox(width: 16),

          // Level Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Card(
                elevation: 4,
                color: AbhyasTheme.darkSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isApproved ? AbhyasTheme.leaf.withValues(alpha: 0.3) : AbhyasTheme.line,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelDetailScreen(
                          level: level,
                          isUnlocked: isApproved,
                          safetyProfile: widget.safetyProfile,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LEVEL ${level.id}',
                              style: TextStyle(
                                color: AbhyasTheme.saffron,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getGateColor(level.gate).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                level.gate.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getGateColor(level.gate),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          level.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${level.practices.length} practices · ${level.ratioLadder.isNotEmpty ? "${level.ratioLadder.length} ratios" : "advanced"}',
                          style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              isApproved
                                  ? 'Unlocked · Tap to practice'
                                  : (hasPending ? 'Pending Teacher Review' : 'Locked · View Requirements'),
                              style: TextStyle(
                                color: isApproved ? AbhyasTheme.leaf : Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGateColor(String gate) {
    switch (gate) {
      case 'self':
        return AbhyasTheme.leaf;
      case 'streak':
        return AbhyasTheme.sky;
      case 'teacher':
        return AbhyasTheme.saffron;
      case 'guru_only':
      default:
        return Colors.purpleAccent;
    }
  }
}
