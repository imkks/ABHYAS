import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../practice/cycle_composer_screen.dart';
import '../dhyan/dhyan_screen.dart';

class TodayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aaj (Today)'),
        elevation: 0,
        actions: [
           IconButton(icon: Icon(Icons.settings), onPressed: () {})
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text('Namaste, Practitioner', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AbhyasTheme.saffron)),
          Text('Sunday · Ekadashi (Phase 3)', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
          SizedBox(height: 30),

          _buildMuhurtaCard(),
          SizedBox(height: 16),
          _buildSankalpCard(context),
          SizedBox(height: 16),
          _buildPracticeCard(context),
          SizedBox(height: 16),
          _buildMalaCard(),
          SizedBox(height: 16),
          _buildEveningCard(context),

        ],
      ),
    );
  }

  Widget _buildMuhurtaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_twilight, color: AbhyasTheme.sky),
                SizedBox(width: 8),
                Text('Brahma Muhurta', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text('4:52 AM – 5:40 AM', style: TextStyle(fontSize: 18)),
            Text('Sunrise: 6:28 AM · Local', style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSankalpCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.handshake, color: AbhyasTheme.clay),
        title: Text('"Today my intention is to practice steadiness."'),
        trailing: Icon(Icons.edit, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit Sankalp placeholder')));
        },
      ),
    );
  }

  Widget _buildPracticeCard(BuildContext context) {
    return Card(
      color: AbhyasTheme.saffron.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AbhyasTheme.saffron, width: 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Practice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AbhyasTheme.saffron)),
            SizedBox(height: 8),
            Text('Full cycle · 30 min', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
            Text('Kapalbhati → Nadi Shodhana → Ujjayi', style: TextStyle(color: AbhyasTheme.darkInkSoft)),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => CycleComposerScreen()));
                    },
                    child: Text('Begin')
                  ),
                ),
                SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CycleComposerScreen()));
                  },
                  child: Text('Adjust Cycle'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMalaCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.spa, color: AbhyasTheme.saffron),
        title: Text('Mala Progress'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            LinearProgressIndicator(value: 41/108, color: AbhyasTheme.saffron, backgroundColor: AbhyasTheme.darkSurfaceAlt),
            SizedBox(height: 4),
            Text('41 of 108 beads completed', style: TextStyle(fontSize: 12))
          ],
        ),
      ),
    );
  }

  Widget _buildEveningCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.bedtime, color: Colors.indigo.shade300),
        title: Text('Evening Practice'),
        subtitle: Text('Yoga Nidra · 30 min'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade400),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => DhyanScreen()));
          },
          child: Text('Go to Dhyan')
        ),
      ),
    );
  }
}
