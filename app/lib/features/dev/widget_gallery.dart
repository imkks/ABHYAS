import 'package:flutter/material.dart';
import '../../widgets/shared_components.dart';
import '../../core/theme.dart';

class WidgetGalleryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Component Gallery')),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          _buildSectionTitle('Buttons'),
          PrimaryButton(text: 'Primary Button', onPressed: () {}),
          SizedBox(height: 10),
          PrimaryButton(text: 'Primary Loading', isLoading: true, onPressed: () {}),
          SizedBox(height: 10),
          SecondaryButton(text: 'Secondary Button', onPressed: () {}),
          SizedBox(height: 20),

          _buildSectionTitle('Safety Controls'),
          StopButton(onPressed: () {}),
          SizedBox(height: 20),

          _buildSectionTitle('Phase Pills'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PhasePill(phase: 'Puraka', color: AbhyasTheme.sky),
              PhasePill(phase: 'Antar Kumbhaka', color: AbhyasTheme.hold),
              PhasePill(phase: 'Rechaka', color: AbhyasTheme.saffron),
              PhasePill(phase: 'Bahya Kumbhaka', color: AbhyasTheme.clay),
            ],
          ),
          SizedBox(height: 20),

          _buildSectionTitle('Lock Badges'),
          LockBadge(type: 'safety', reason: 'Consult doctor due to health flags.'),
          SizedBox(height: 10),
          LockBadge(type: 'teacher', reason: 'Requires Guru Anumati.'),
          SizedBox(height: 20),

          _buildSectionTitle('Big Counter'),
          Center(child: BigCounter(value: '08', subtitle: 'of 12 sec max')),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
      child: Text(title, style: TextStyle(color: AbhyasTheme.saffron, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
