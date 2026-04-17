import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/fixture.dart';
import '../models/match_details.dart';
import '../models/status.dart';
import 'api_service.dart';
import 'espn_service.dart';

class MatchDetailsService {
  static Future<MatchDetails?> load(Fixture fixture) async {
    if (fixture.status == MatchStatus.upcoming) return null;

    final box = await Hive.openBox<MatchDetails>('match_details');
    final cached = box.get(fixture.id.toString());
    if (cached != null && fixture.status == MatchStatus.finished) {
      return cached;
    }

    try {
      final details = fixture.sport == 'football'
          ? await _fetchFootball(fixture)
          : await _fetchEspn(fixture);

      final hasData = details.stats.isNotEmpty || details.plays.isNotEmpty;
      if (fixture.status == MatchStatus.finished && hasData) {
        await box.put(fixture.id.toString(), details);
      }
      return details;
    } catch (e, st) {
      print('MatchDetails fetch error for ${fixture.id}: $e\n$st');
      return cached;
    }
  }

  static Future<MatchDetails> _fetchEspn(Fixture fixture) async {
    final response = await EspnService.summary(
      sportId: fixture.sport,
      leagueSlug: fixture.leagueId,
      eventId: fixture.id.toString(),
    );
    if (response.statusCode != 200) {
      throw Exception('ESPN summary failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MatchDetails(
      fixtureId: fixture.id,
      stats: _parseEspnStats(json),
      plays: _parseEspnPlays(json),
      fetchedAt: DateTime.now(),
    );
  }

  static List<StatRow> _parseEspnStats(Map<String, dynamic> json) {
    final boxscore = (json['boxscore'] as Map?)?.cast<String, dynamic>() ?? {};
    final teams = (boxscore['teams'] as List?) ?? const [];
    Map<String, String> homeStats = {};
    Map<String, String> awayStats = {};
    for (final t in teams) {
      final m = (t as Map).cast<String, dynamic>();
      final side = (m['homeAway'] ?? '').toString();
      final stats = (m['statistics'] as List?) ?? const [];
      final parsed = <String, String>{};
      for (final s in stats) {
        final sm = (s as Map).cast<String, dynamic>();
        final label = (sm['label'] ?? sm['name'] ?? '').toString();
        final value = (sm['displayValue'] ?? sm['value'] ?? '').toString();
        if (label.isEmpty) continue;
        parsed[label] = value;
      }
      if (side == 'home') homeStats = parsed;
      if (side == 'away') awayStats = parsed;
    }
    final labels = <String>{...homeStats.keys, ...awayStats.keys};
    return [
      for (final label in labels)
        StatRow(
          label: label,
          home: homeStats[label] ?? '',
          away: awayStats[label] ?? '',
        ),
    ];
  }

  static List<MatchPlay> _parseEspnPlays(Map<String, dynamic> json) {
    final plays = (json['plays'] as List?) ?? const [];
    return [
      for (final p in plays)
        MatchPlay(
          text: ((p as Map)['text'] ?? '').toString(),
          period: (_asMap(p['period'])['displayValue'] ??
                  _asMap(p['period'])['number'] ??
                  '')
              .toString(),
          clock: (_asMap(p['clock'])['displayValue'] ?? '').toString(),
        ),
    ];
  }

  static Future<MatchDetails> _fetchFootball(Fixture fixture) async {
    final results = await Future.wait([
      ApiService.get('/fixtures/statistics?fixture=${fixture.id}', sport: 'football'),
      ApiService.get('/fixtures/events?fixture=${fixture.id}', sport: 'football'),
    ]);
    final statsResp = results[0];
    final eventsResp = results[1];

    List<StatRow> stats = const [];
    if (statsResp.statusCode == 200) {
      print('Football stats raw body: ${statsResp.body}');
      stats = _parseFootballStats(jsonDecode(statsResp.body), fixture);
      print('Football stats parsed: ${stats.length} rows');
    } else {
      print('Football stats failed: ${statsResp.statusCode} body=${statsResp.body}');
    }

    List<MatchPlay> plays = const [];
    if (eventsResp.statusCode == 200) {
      plays = _parseFootballEvents(jsonDecode(eventsResp.body), fixture);
      print('Football events parsed: ${plays.length} plays');
    } else {
      print('Football events failed: ${eventsResp.statusCode}');
    }

    return MatchDetails(
      fixtureId: fixture.id,
      stats: stats,
      plays: plays,
      fetchedAt: DateTime.now(),
    );
  }

  static List<StatRow> _parseFootballStats(dynamic json, Fixture fixture) {
    final response = (json is Map ? json['response'] : null) as List? ?? const [];
    print('_parseFootballStats: response.length=${response.length}; home=${fixture.homeTeamId} away=${fixture.awayTeamId}');
    Map<String, String> homeStats = {};
    Map<String, String> awayStats = {};
    for (final t in response) {
      final m = (t as Map).cast<String, dynamic>();
      final teamId = _asInt(_asMap(m['team'])['id']);
      final rawStats = (m['statistics'] as List?) ?? const [];
      final parsed = <String, String>{};
      for (final s in rawStats) {
        final sm = (s as Map).cast<String, dynamic>();
        final type = (sm['type'] ?? '').toString();
        final value = sm['value']?.toString() ?? '';
        if (type.isEmpty) continue;
        parsed[type] = value;
      }
      print('_parseFootballStats: team=$teamId stats=${parsed.length}');
      if (teamId == fixture.homeTeamId) {
        homeStats = parsed;
      } else if (teamId == fixture.awayTeamId) {
        awayStats = parsed;
      } else if (homeStats.isEmpty) {
        homeStats = parsed;
      } else if (awayStats.isEmpty) {
        awayStats = parsed;
      }
    }
    print('_parseFootballStats: home=${homeStats.length} away=${awayStats.length}');
    final labels = <String>{...homeStats.keys, ...awayStats.keys};
    return [
      for (final label in labels)
        StatRow(
          label: label,
          home: homeStats[label] ?? '',
          away: awayStats[label] ?? '',
        ),
    ];
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }


  static List<MatchPlay> _parseFootballEvents(dynamic json, Fixture fixture) {
    final response = (json is Map ? json['response'] : null) as List? ?? const [];
    final plays = <MatchPlay>[];
    for (final e in response) {
      final m = (e as Map).cast<String, dynamic>();
      final time = _asMap(m['time']);
      final elapsed = time['elapsed']?.toString() ?? '';
      final extra = time['extra'];
      final clock = extra != null ? "$elapsed+$extra'" : "$elapsed'";
      final type = (m['type'] ?? '').toString();
      final detail = (m['detail'] ?? '').toString();
      final team = (_asMap(m['team'])['name'] ?? '').toString();
      final player = (_asMap(m['player'])['name'] ?? '').toString();
      final text = '$type - $detail - $player ($team)';
      plays.add(MatchPlay(text: text, period: '', clock: clock));
    }
    plays.sort((a, b) => _clockToInt(a.clock).compareTo(_clockToInt(b.clock)));
    return plays;
  }

  static int _clockToInt(String clock) {
    final cleaned = clock.replaceAll("'", '').split('+');
    final base = int.tryParse(cleaned.first) ?? 0;
    final add = cleaned.length > 1 ? (int.tryParse(cleaned[1]) ?? 0) : 0;
    return base * 100 + add;
  }

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
}
