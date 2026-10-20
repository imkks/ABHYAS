import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../engine/config/config_models.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import '../../engine/safety/safety_rules_engine.dart';
import '../../widgets/shared_components.dart';
import '../practice/practice_player_screen.dart';
import 'unlock_request_dialog.dart';

class LevelDetailScreen extends StatefulWidget {
  final SopanaLevel level;
  final bool isUnlocked;
  final SafetyProfile safetyProfile;

  const LevelDetailScreen({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.safetyProfile,
  });

  @override
  State<LevelDetailScreen> createState() => _LevelDetailScreenState();
}

class _LevelDetailScreenState extends State<LevelDetailScreen> {
  void _openUnlockDialog() {
    showDialog(
      context: context,
      builder: (context) => UnlockRequestDialog(
        level: widget.level,
        onRequestSubmitted: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflow = GuruAnumatiWorkflow();
    final hasPendingRequest = workflow.requests.any(
      (r) => r.requestedLevel == widget.level.id && r.status == UnlockStatus.pending,
    );
    final approved = widget.level.id <= 2 || workflow.isLevelApproved(widget.level.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sopana ${widget.level.id}: ${widget.level.name}'),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          // Header card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AbhyasTheme.darkSurface, AbhyasTheme.darkSurfaceAlt],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: approved ? AbhyasTheme.leaf : AbhyasTheme.line,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sopana ${widget.level.id}',
                      style: TextStyle(
                        color: AbhyasTheme.saffron,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    _buildGateBadge(widget.level.gate),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  widget.level.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      approved ? Icons.lock_open : Icons.lock,
                      size: 16,
                      color: approved ? AbhyasTheme.leaf : Colors.orange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      approved
                          ? 'Available for Sadhana'
                          : (hasPendingRequest
                              ? 'Request Pending Review'
                              : 'Locked · Gate: ${widget.level.gate}'),
                      style: TextStyle(
                        color: approved ? AbhyasTheme.leaf : Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Practices Section
          Text(
            'Core Practices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 12),
          ...widget.level.practices.map((practice) => _buildPracticeTile(practice, approved)),

          SizedBox(height: 24),

          // Ratio Ladder Section
          if (widget.level.ratioLadder.isNotEmpty) ...[
            Text(
              'Ratio Progression Ladder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AbhyasTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: widget.level.ratioLadder.map((ratio) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ratio[0]} : ${ratio[1]} : ${ratio[2]} : ${ratio[3]}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AbhyasTheme.saffron,
                          ),
                        ),
                        Text(
                          'Puraka : Antar : Rechaka : Bahya',
                          style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 24),
          ],

          // Mudras & Bandhas
          if (widget.level.mudras.isNotEmpty || widget.level.bandhas.isNotEmpty) ...[
            Text(
              'Mudras & Bandhas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.level.mudras.map((m) => _buildPill('Mudra: $m', AbhyasTheme.sky)),
                ...widget.level.bandhas.map((b) => _buildPill('Bandha: $b', AbhyasTheme.clay)),
              ],
            ),
            SizedBox(height: 24),
          ],

          // Pariksha Gate Criteria
          Text(
            'Pariksha (Progression Gate)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AbhyasTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.level.pariksha.summaryDescription,
              style: TextStyle(color: AbhyasTheme.darkInkSoft, height: 1.4),
            ),
          ),

          SizedBox(height: 36),

          // Primary Action
          if (approved)
            PrimaryButton(
              text: 'Practice ${widget.level.practices.first}',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PracticePlayerScreen(
                      safetyProfile: widget.safetyProfile,
                      practiceName: widget.level.practices.first.replaceAll('_', ' ').toUpperCase(),
                      practiceId: widget.level.practices.first,
                    ),
                  ),
                );
              },
            )
          else if (widget.level.requiresTeacherApproval)
            ElevatedButton(
              onPressed: hasPendingRequest ? null : _openUnlockDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AbhyasTheme.saffron,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                hasPendingRequest ? 'Request Pending Review' : 'Request Guru Anumati',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPracticeTile(String practiceId, bool unlocked) {
    final title = practiceId.replaceAll('_', ' ').toUpperCase();
    return Card(
      color: AbhyasTheme.darkSurface,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.self_improvement,
          color: unlocked ? AbhyasTheme.leaf : Colors.grey,
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(
          unlocked ? Icons.chevron_right : Icons.lock,
          color: unlocked ? Colors.white : Colors.grey,
          size: 20,
        ),
        onTap: unlocked
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PracticePlayerScreen(
                      safetyProfile: widget.safetyProfile,
                      practiceName: title,
                      practiceId: practiceId,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildGateBadge(String gate) {
    Color color;
    switch (gate) {
      case 'self':
        color = AbhyasTheme.leaf;
        break;
      case 'streak':
        color = AbhyasTheme.sky;
        break;
      case 'teacher':
        color = AbhyasTheme.saffron;
        break;
      case 'guru_only':
      default:
        color = Colors.purpleAccent;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        gate.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
