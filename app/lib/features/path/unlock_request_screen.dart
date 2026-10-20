import 'package:flutter/material.dart';
import '../../engine/progression/guru_anumati_workflow.dart';

class UnlockRequestScreen extends StatefulWidget {
  final int levelId;
  final String levelName;

  const UnlockRequestScreen({
    Key? key,
    required this.levelId,
    required this.levelName,
  }) : super(key: key);

  @override
  _UnlockRequestScreenState createState() => _UnlockRequestScreenState();
}

class _UnlockRequestScreenState extends State<UnlockRequestScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSending = false;

  void _sendRequest() async {
    setState(() => _isSending = true);

    final workflow = GuruAnumatiWorkflow();
    await workflow.requestUnlock('student-123', widget.levelId, note: _noteController.text);

    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock request sent to teacher.')),
      );
      Navigator.pop(context); // Go back to level detail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Unlock')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request to unlock Level ${widget.levelId}: ${widget.levelName}',
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Optional note to teacher',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('By sending this request, you agree to share your recent practice data with your teacher.',
                 style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSending ? null : _sendRequest,
              child: _isSending ? const CircularProgressIndicator() : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }
}
