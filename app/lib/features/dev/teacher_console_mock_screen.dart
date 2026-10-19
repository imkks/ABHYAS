import 'package:flutter/material.dart';
import '../../engine/progression/guru_anumati_workflow.dart';

class TeacherConsoleMockScreen extends StatefulWidget {
  final GuruAnumatiWorkflow workflow;

  const TeacherConsoleMockScreen({Key? key, required this.workflow}) : super(key: key);

  @override
  _TeacherConsoleMockScreenState createState() => _TeacherConsoleMockScreenState();
}

class _TeacherConsoleMockScreenState extends State<TeacherConsoleMockScreen> {
  List<UnlockRequest> _pendingRequests = [];
  List<UnlockRequest> _pastRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final allRequests = await widget.workflow.getRequests();
    if (mounted) {
      setState(() {
        _pendingRequests = allRequests.where((r) => r.status == UnlockStatus.pending).toList();
        _pastRequests = allRequests.where((r) => r.status != UnlockStatus.pending).toList();
      });
    }
  }

  void _simulateTeacherAction(int level, bool approve) async {
    await widget.workflow.simulateTeacherApproval(level, approve, approve ? 'Good progress.' : 'Needs more practice.');
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teacher Console (Mock)')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._pendingRequests.map((r) => Card(
            child: ListTile(
              title: Text('Student ${r.studentId} wants Level ${r.requestedLevel}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _simulateTeacherAction(r.requestedLevel, true),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _simulateTeacherAction(r.requestedLevel, false),
                  ),
                ],
              ),
            ),
          )),
          if (_pendingRequests.isEmpty)
            Padding(padding: EdgeInsets.all(16), child: Text('No pending requests.')),

          SizedBox(height: 30),
          Text('Past Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._pastRequests.map((r) => ListTile(
            title: Text('Student ${r.studentId} - Level ${r.requestedLevel}'),
            subtitle: Text('Status: ${r.status.name}\nNote: ${r.teacherNote ?? "None"}'),
          ))
        ],
      ),
    );
  }
}
