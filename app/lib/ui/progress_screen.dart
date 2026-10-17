import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Progress')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildStatCard('Current Sopana', '2 (Abhyasa)', Icons.stairs),
          _buildStatCard('Tapas Points', '450', Icons.local_fire_department),
          _buildStatCard('Vishrama Days Left', '1', Icons.weekend),
          _buildStatCard('Comfort Hold Time (CHT)', '22s', Icons.timer),

          SizedBox(height: 30),
          Text('Mudra & Bandha Seals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSeal('Gyan', true),
              _buildSeal('Chin', true),
              _buildSeal('Dhyana', true),
              _buildSeal('Nasika', false),
              _buildSeal('Jalandhara', false),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.orange),
        title: Text(title),
        trailing: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSeal(String name, bool earned) {
    return Chip(
      avatar: Icon(
        earned ? Icons.check_circle : Icons.lock,
        color: earned ? Colors.green : Colors.grey
      ),
      label: Text(name),
      backgroundColor: earned ? Colors.green.shade100 : Colors.grey.shade200,
    );
  }
}
