import 'package:flutter/material.dart';
import '../models/fixture.dart';
import '../models/status.dart';

class MatchOverview extends StatelessWidget {
  final Fixture fixture;
  const MatchOverview({super.key, required this.fixture});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _TeamBlock(
                  name: fixture.homeTeamName,
                  logo: fixture.homeTeamLogo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${fixture.homeScore ?? '-'}  :  ${fixture.awayScore ?? '-'}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _TeamBlock(
                  name: fixture.awayTeamName,
                  logo: fixture.awayTeamLogo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fixture.leagueName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (fixture.venue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fixture.venue,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 8),
          _StatusBadge(status: fixture.status),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String logo;
  const _TeamBlock({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (logo.isEmpty)
          const Icon(Icons.shield, size: 56, color: Colors.grey)
        else
          Image.network(
            logo,
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.shield, size: 56, color: Colors.grey),
          ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;
  const _StatusBadge({required this.status});

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
      child: Text(
        status.display.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
