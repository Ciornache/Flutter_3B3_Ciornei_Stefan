import 'package:flutter/material.dart';
import '../models/status.dart';

class StatusBadge extends StatelessWidget {
  final MatchStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MatchStatus.upcoming => Colors.blueGrey,
      MatchStatus.live => Colors.red,
      MatchStatus.finished => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MatchStatus.live) ...[
            Icon(Icons.fiber_manual_record, size: 8, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status.display.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
