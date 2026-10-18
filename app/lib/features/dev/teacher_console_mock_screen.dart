import 'package:flutter/material.dart';
import '../../../../progression/guru_anumati_workflow.dart';
import 'widget_gallery.dart';

class TeacherConsoleMockScreen extends StatefulWidget {
  final GuruAnumatiWorkflow workflow;

  const TeacherConsoleMockScreen({Key? key, required this.workflow}) : super(key: key);

  @override
  _TeacherConsoleMockScreenState createState() => _TeacherConsoleMockScreenState();
}

class _TeacherConsoleMockScreenState extends State<TeacherConsoleMockScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingRequests = widget.workflow.requests.where((r) => r.status == UnlockStatus.pending).toList();
    final pastRequests = widget.workflow.requests.where((r) => r.status != UnlockStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Teacher Console Mock')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Pending Approvals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
          if (pendingRequests.isEmpty) Text('No pending requests.'),
          ...pendingRequests.map((req) => Card(
            child: ListTile(
              title: Text('Student requested Level ${req.requestedLevel}'),
              subtitle: Text('Review their CHT and recent sessions.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        widget.workflow.simulateTeacherApproval(req.requestedLevel, true, 'Approved.');
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        widget.workflow.simulateTeacherApproval(req.requestedLevel, false, 'Needs more time.');
                      });
                    },
                  ),
                ],
              ),
            ),
          )),
          SizedBox(height: 30),
          Text('Past Approvals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          ...pastRequests.map((req) => ListTile(
            title: Text('Level ${req.requestedLevel}'),
            subtitle: Text('Status: ${req.status.name.toUpperCase()}'),
            trailing: Icon(
              req.status == UnlockStatus.approved ? Icons.check_circle : Icons.cancel,
              color: req.status == UnlockStatus.approved ? Colors.green : Colors.red,
            ),
          )),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => WidgetGalleryScreen()));
            },
            child: Text('View Component Gallery (Dev)')
          )
        ],
      ),
    );
  }
}
