import 'package:flutter/material.dart';

class RitualsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vedic Rituals'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text('Pre-Practice Flow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.deepOrange)),
          SizedBox(height: 16),
          _buildRitualCard(context, 'Achamana', 'Purification', 'Sip water 3 times with specific mantras.', Icons.water_drop, Colors.blue, 'Om Keshavaya Namah, Om Narayanaya Namah, Om Madhavaya Namah.'),
          _buildRitualCard(context, 'Desha-Kala (Panchang)', 'Time & Space', 'Align your consciousness with today\'s Tithi, Nakshatra, and sacred Muhurta.', Icons.calendar_month, Colors.amber, 'Vedic sadhana begins by locating awareness in cosmic time and space (Desha-Kala Sankalpa). Contemplate today\'s prevailing solar and lunar energies to tune your breath.'),
          _buildRitualCard(context, 'Asana Sthapana', 'Seat', 'Establish your seat.', Icons.chair_alt, Colors.brown, '[CONTENT PENDING - TEACHER REVIEW]'),
          _buildRitualCard(context, 'Sankalp', 'Intention', 'Formulate your intention.', Icons.handshake, Colors.orange, 'I practice today for steadiness of mind and body.'),

          SizedBox(height: 40),
          Text('Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.deepOrange)),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16)
            ),
            child: Column(
              children: [
                _buildMantraTile(context, 'Om Chanting', 'A-U-M. The primordial sound.'),
                Divider(height: 1, color: Colors.grey.shade800),
                _buildMantraTile(context, 'Gayatri Mantra', 'Om Bhur Bhuva Swaha...'),
                Divider(height: 1, color: Colors.grey.shade800),
                _buildMantraTile(context, 'Patanjali Invocation', 'Yogena cittasya padena vacam...'),
                Divider(height: 1, color: Colors.grey.shade800),
                _buildMantraTile(context, 'Guru Vandana', 'Gurur Brahma Gurur Vishnu...'),
                Divider(height: 1, color: Colors.grey.shade800),
                _buildMantraTile(context, 'Shanti Path', 'Om Sahana Vavatu...'),
              ],
            )
          )
        ],
      ),
    );
  }

  Widget _buildRitualCard(BuildContext context, String title, String subtitleTag, String description, IconData icon, Color color, String detail) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRitualDetail(context, title, detail),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
                          child: Text(subtitleTag, style: TextStyle(fontSize: 10, color: Colors.grey.shade300)),
                        )
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ]
                )
              ),
              Icon(Icons.chevron_right, color: Colors.grey)
            ],
          )
        )
      )
    );
  }

  Widget _buildMantraTile(BuildContext context, String title, String preview) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(preview, style: TextStyle(color: Colors.grey.shade500)),
      trailing: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.volume_up, color: Colors.deepOrange),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playing $title audio...')));
      },
    );
  }

  void _showRitualDetail(BuildContext context, String title, String detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: Colors.deepOrange)),
        content: Text(detail, style: TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}
