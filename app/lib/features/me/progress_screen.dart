import 'package:flutter/material.dart';
import '../../engine/progression/guru_anumati_workflow.dart';
import '../../engine/progression/weaning_ladder.dart';
import '../../engine/progression/tapas_manager.dart';
import 'privacy_tools_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _currentLevel = 2;
  int _malaBeads = 42;
  final GuruAnumatiWorkflow _workflow = GuruAnumatiWorkflow();
  final WeaningLadder _weaningLadder = WeaningLadder();
  final TapasManager _tapasManager = TapasManager();

  @override
  Widget build(BuildContext context) {
    int nextLevel = _currentLevel + 1;
    final hasPendingRequest = _workflow.requests.any((r) => r.requestedLevel == nextLevel && r.status == UnlockStatus.pending);
    final isApproved = _workflow.isLevelApproved(nextLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Level Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Current Level: $_currentLevel', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Mala Beads: $_malaBeads / 108', style: const TextStyle(fontSize: 18)),
                  LinearProgressIndicator(value: _malaBeads / 108),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Weaning Stage
          Card(
            child: ListTile(
              leading: const Icon(Icons.escalator_warning, color: Colors.blue),
              title: Text('Weaning Stage: ${_weaningLadder.currentStage}'),
              subtitle: Text('Status: ${_weaningLadder.getStageDescription()}'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _weaningLadder.advanceStage();
                  });
                },
                child: const Text('Advance'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tapas Points
          Card(
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Tapas Points'),
              trailing: Text('${_tapasManager.tapasPoints}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() {
                  _tapasManager.addPoints(10);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock: Earned 10 Tapas Points for Brahma Muhurta practice!')));
              },
            ),
          ),
          const SizedBox(height: 16),
          // Guru Anumati Request
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.red),
                  title: Text('Next Level ($nextLevel) Gate'),
                  subtitle: const Text('Requires Teacher Approval (Guru Anumati)'),
                ),
                if (isApproved)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentLevel = nextLevel;
                        });
                      },
                      child: const Text('Unlock Level'),
                    ),
                  )
                else if (!hasPendingRequest)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _workflow.requestUnlock("test-student-id", nextLevel);
                        });
                      },
                      child: const Text('Request Unlock'),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Request pending teacher review...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),
                if (hasPendingRequest)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _workflow.simulateTeacherApproval(nextLevel, true, 'Good progress.');
                          });
                        },
                        child: const Text('(Mock Approve)', style: TextStyle(color: Colors.green)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _workflow.simulateTeacherApproval(nextLevel, false, 'Needs more practice.');
                          });
                        },
                        child: const Text('(Mock Deny)', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy & Data Tools'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyToolsScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
