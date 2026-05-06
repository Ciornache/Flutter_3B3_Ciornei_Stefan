import 'package:flutter/material.dart';
import '../models/fixture.dart';
import 'team_logo.dart';

class FixtureCard extends StatelessWidget {
  final Fixture fixture;
  final bool sportFilterActive;
  final VoidCallback? onTap;

  const FixtureCard({
    super.key,
    required this.fixture,
    this.sportFilterActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: _TeamSide(
                teamName: fixture.homeTeamName,
                logoUrl: fixture.homeTeamLogo,
                score: fixture.homeScore,
                alignEnd: false,
              ),
            ),
            Expanded(
              flex: 3,
              child: _MiddleInfo(
                fixture: fixture,
                sportFilterActive: sportFilterActive,
              ),
            ),
            Expanded(
              flex: 4,
              child: _TeamSide(
                teamName: fixture.awayTeamName,
                logoUrl: fixture.awayTeamLogo,
                score: fixture.awayScore,
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  final String teamName;
  final String logoUrl;
  final int? score;
  final bool alignEnd;

  const _TeamSide({
    required this.teamName,
    required this.logoUrl,
    required this.score,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final logo = TeamLogo(url: logoUrl);
    final name = Expanded(
      child: Text(
        teamName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
    final scoreText = Text(
      score?.toString() ?? '-',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );

    final children = alignEnd
        ? [scoreText, const SizedBox(width: 8), name, const SizedBox(width: 8), logo]
        : [logo, const SizedBox(width: 8), name, const SizedBox(width: 8), scoreText];

    return Row(children: children);
  }
}

class _MiddleInfo extends StatelessWidget {
  final Fixture fixture;
  final bool sportFilterActive;
  const _MiddleInfo({required this.fixture, required this.sportFilterActive});

  @override
  Widget build(BuildContext context) {
    final time =
        '${fixture.date.hour.toString().padLeft(2, '0')}:${fixture.date.minute.toString().padLeft(2, '0')}';
    final sportLabel = fixture.sport
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    final topText = sportFilterActive ? fixture.leagueName : sportLabel;
    final midText = sportFilterActive ? fixture.venue : fixture.leagueName;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          topText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          midText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
