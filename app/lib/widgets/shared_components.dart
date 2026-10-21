import 'package:flutter/material.dart';
import '../core/theme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AbhyasTheme.darkBg, strokeWidth: 2))
        : Text(text),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class StopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64, // Touch target >= 64dp per spec
        decoration: BoxDecoration(
          color: AbhyasTheme.clay.withValues(alpha: 0.2),
          border: Border.all(color: AbhyasTheme.clay),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text('RETURN TO NATURAL BREATH', style: TextStyle(color: AbhyasTheme.clay, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ),
      ),
    );
  }
}

class PhasePill extends StatelessWidget {
  final String phase;
  final Color color;

  const PhasePill({super.key, required this.phase, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lens, color: color, size: 12),
          SizedBox(width: 8),
          Text(phase.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      )
    );
  }
}

class LockBadge extends StatelessWidget {
  final String type; // 'teacher', 'guru', 'safety'
  final String reason;

  const LockBadge({super.key, required this.type, required this.reason});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = type == 'safety' ? AbhyasTheme.clay : Colors.grey.shade500;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5))
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: badgeColor, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locked', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold)),
                Text(reason, style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 13)),
              ],
            )
          )
        ],
      ),
    );
  }
}

class BigCounter extends StatelessWidget {
  final String value;
  final String subtitle;

  const BigCounter({super.key, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 84,
            fontWeight: FontWeight.w200,
            color: AbhyasTheme.darkInk,
            fontFeatures: [FontFeature.tabularFigures()]
          ),
        ),
        Text(subtitle, style: TextStyle(color: AbhyasTheme.darkInkSoft, fontSize: 16)),
      ],
    );
  }
}
