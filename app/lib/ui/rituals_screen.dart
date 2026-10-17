import 'package:flutter/material.dart';

class RitualsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vedic Rituals')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Pre-Practice Flow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.water_drop, color: Colors.blue),
              title: Text('Achamana (Purification)'),
              subtitle: Text('Sip water 3 times with specific mantras.'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showRitualDetail(context, 'Achamana', 'Om Keshavaya Namah, Om Narayanaya Namah, Om Madhavaya Namah.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.chair_alt, color: Colors.brown),
              title: Text('Asana Sthapana'),
              subtitle: Text('Establish your seat.'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showRitualDetail(context, 'Asana Sthapana', '[CONTENT PENDING - TEACHER REVIEW]'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.handshake, color: Colors.orange),
              title: Text('Sankalp'),
              subtitle: Text('Formulate your intention.'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showRitualDetail(context, 'Sankalp', 'I practice today for steadiness of mind and body.'),
            ),
          ),

          SizedBox(height: 30),
          Text('Mantra & Invocation Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _buildMantraTile(context, 'Om Chanting', 'A-U-M. The primordial sound.'),
          _buildMantraTile(context, 'Gayatri Mantra', 'Om Bhur Bhuva Swaha...'),
          _buildMantraTile(context, 'Patanjali Invocation', 'Yogena cittasya padena vacam...'),
          _buildMantraTile(context, 'Guru Vandana', 'Gurur Brahma Gurur Vishnu...'),
          _buildMantraTile(context, 'Shanti Path', 'Om Sahana Vavatu...'),
        ],
      ),
    );
  }

  Widget _buildMantraTile(BuildContext context, String title, String preview) {
    return ListTile(
      title: Text(title),
      subtitle: Text(preview),
      trailing: Icon(Icons.volume_up),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing ${title} audio...')));
      },
    );
  }

  void _showRitualDetail(BuildContext context, String title, String detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))
        ],
      ),
    );
  }
}
