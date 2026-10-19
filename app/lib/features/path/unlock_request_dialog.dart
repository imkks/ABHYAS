import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../engine/config/config_models.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import '../../data/session_repository.dart';
import '../../data/user_repository.dart';

class UnlockRequestDialog extends StatefulWidget {
  final SopanaLevel level;
  final VoidCallback? onRequestSubmitted;

  const UnlockRequestDialog({
    Key? key,
    required this.level,
    this.onRequestSubmitted,
  }) : super(key: key);

  @override
  _UnlockRequestDialogState createState() => _UnlockRequestDialogState();
}

class _UnlockRequestDialogState extends State<UnlockRequestDialog> {
  int _completedSessions = 0;
  int _comfortStreak = 0;
  double? _chtBenchmark;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checkPrerequisites();
  }

  Future<void> _checkPrerequisites() async {
    final sessionRepo = SessionRepository();
    final userRepo = UserRepository();

    final sessions = await sessionRepo.getTapasCount();
    final streak = await sessionRepo.getComfortStreak();
    final cht = await userRepo.loadChtBenchmark();

    if (mounted) {
      setState(() {
        _completedSessions = sessions;
        _comfortStreak = streak;
        _chtBenchmark = cht;
        _loading = false;
      });
    }
  }

  void _submitRequest() {
    setState(() => _submitting = true);
    final workflow = GuruAnumatiWorkflow();
    workflow.requestUnlock('practitioner-1', widget.level.id);

    Navigator.pop(context);
    widget.onRequestSubmitted?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guru Anumati request for Level ${widget.level.id} (${widget.level.name}) submitted.'),
        backgroundColor: AbhyasTheme.saffron,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pariksha = widget.level.pariksha;
    final minSessionsMet = pariksha.minSessions == null || _completedSessions >= pariksha.minSessions!;
    final streakMet = pariksha.consecutiveDaysWindow == null || _comfortStreak >= 7;

    return AlertDialog(
      backgroundColor: AbhyasTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.shield_outlined, color: AbhyasTheme.saffron),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Guru Anumati: Level ${widget.level.id}',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      content: _loading
          ? SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${widget.level.id} (${widget.level.name}) requires teacher permission before practice can commence.',
                    style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text('Pariksha Checklist:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),

                  if (pariksha.minSessions != null)
                    _buildCheckItem(
                      'Completed Sessions: $_completedSessions / ${pariksha.minSessions}',
                      minSessionsMet,
                    ),

                  if (pariksha.consecutiveDaysWindow != null)
                    _buildCheckItem(
                      'Comfort Streak: $_comfortStreak days',
                      streakMet,
                    ),

                  if (pariksha.chtRequired)
                    _buildCheckItem(
                      'CHT Benchmark: ${_chtBenchmark != null ? "${_chtBenchmark!.toStringAsFixed(0)}s recorded" : "Pending self-check test"}',
                      _chtBenchmark != null && _chtBenchmark! >= 12,
                    ),

                  if (pariksha.liveOrVideoReview)
                    _buildCheckItem(
                      'Bandha alignment review required',
                      false,
                      isInfo: true,
                    ),

                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AbhyasTheme.saffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AbhyasTheme.saffron.withOpacity(0.3)),
                    ),
                    child: Text(
                      'By requesting unlock, you confirm commitment to the tradition guidelines and willingness to follow teacher guidance.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submitRequest,
          style: ElevatedButton.styleFrom(backgroundColor: AbhyasTheme.saffron),
          child: _submitting
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Submit Request', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool satisfied, {bool isInfo = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isInfo ? Icons.info_outline : (satisfied ? Icons.check_circle : Icons.radio_button_unchecked),
            size: 18,
            color: isInfo ? AbhyasTheme.sky : (satisfied ? AbhyasTheme.leaf : Colors.grey),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: satisfied ? Colors.white : Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
