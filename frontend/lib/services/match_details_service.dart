import 'package:hive_flutter/hive_flutter.dart';

import '../models/fixture.dart';
import '../models/match_details.dart';
import '../models/status.dart';
import 'backend_service.dart';

class MatchDetailsService {
  static Future<MatchDetails?> load(Fixture fixture) async {
    if (fixture.status == MatchStatus.upcoming) return null;

    final box = await Hive.openBox<MatchDetails>('match_details');
    final cached = box.get(fixture.id.toString());
    if (cached != null && fixture.status == MatchStatus.finished) {
      return cached;
    }

    try {
      final query = <String, String>{
        'status': fixture.status == MatchStatus.finished ? 'finished' : 'live',
      };
      if (fixture.sport == 'football') {
        query['homeTeamId'] = fixture.homeTeamId.toString();
        query['awayTeamId'] = fixture.awayTeamId.toString();
      } else {
        query['league'] = fixture.leagueId;
      }

      final data = await BackendService.getJson(
        '/fixtures/${fixture.sport}/${fixture.id}/details',
        query: query,
      );
      final json = (data as Map).cast<String, dynamic>();
      final details = _parse(fixture.id, json);
      final hasData = details.stats.isNotEmpty || details.plays.isNotEmpty;
      if (fixture.status == MatchStatus.finished && hasData) {
        await box.put(fixture.id.toString(), details);
      }
      return details;
    } catch (_) {
      return cached;
    }
  }

  static MatchDetails _parse(int fixtureId, Map<String, dynamic> json) {
    final statsList = (json['stats'] as List?) ?? const [];
    final playsList = (json['plays'] as List?) ?? const [];
    return MatchDetails(
      fixtureId: fixtureId,
      stats: [
        for (final s in statsList)
          StatRow(
            label: (s as Map)['label'] as String,
            home: s['home'] as String,
            away: s['away'] as String,
          ),
      ],
      plays: [
        for (final p in playsList)
          MatchPlay(
            text: (p as Map)['text'] as String,
            period: p['period'] as String,
            clock: p['clock'] as String,
          ),
      ],
      fetchedAt: DateTime.now(),
    );
  }
}
