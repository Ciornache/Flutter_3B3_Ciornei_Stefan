import 'package:flutter/material.dart';
import '../models/fixture.dart';
import 'status_badge.dart';
import 'team_logo.dart';

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
                  heroTag: 'fixture-${fixture.id}-home',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${fixture.homeScore ?? '-'}  :  ${fixture.awayScore ?? '-'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: _TeamBlock(
                  name: fixture.awayTeamName,
                  logo: fixture.awayTeamLogo,
                  heroTag: 'fixture-${fixture.id}-away',
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
          StatusBadge(status: fixture.status),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String logo;
  final String heroTag;
  const _TeamBlock({
    required this.name,
    required this.logo,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(tag: heroTag, child: TeamLogo(url: logo, size: 56)),
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

