import 'package:hive/hive.dart';
import 'status.dart';

class Fixture {
  final int id;
  final String sport;
  final DateTime date;
  final String leagueId;
  final String leagueName;
  final String leagueLogo;
  final String countryCode;
  final String continent;
  final String statusText;
  final MatchStatus status;
  final String venue;
  final int homeTeamId;
  final String homeTeamName;
  final String homeTeamLogo;
  final int awayTeamId;
  final String awayTeamName;
  final String awayTeamLogo;
  final int? homeScore;
  final int? awayScore;

  Fixture({
    required this.id,
    required this.sport,
    required this.date,
    required this.leagueId,
    required this.leagueName,
    required this.leagueLogo,
    required this.countryCode,
    required this.continent,
    required this.statusText,
    required this.status,
    this.venue = '',
    required this.homeTeamId,
    required this.homeTeamName,
    required this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    required this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
  });

  factory Fixture.fromEspnJson(
    Map<String, dynamic> event,
    String sport, {
    required String leagueId,
    required String leagueName,
    required String leagueLogo,
  }) {
    final competitions = (event['competitions'] as List?) ?? const [];
    final comp = competitions.isNotEmpty ? _asMap(competitions.first) : <String, dynamic>{};
    final competitors = (comp['competitors'] as List?) ?? const [];

    Map<String, dynamic> findSide(String side) {
      for (final c in competitors) {
        final m = _asMap(c);
        if (m['homeAway'] == side) return m;
      }
      return <String, dynamic>{};
    }

    final homeC = findSide('home');
    final awayC = findSide('away');
    final homeTeam = _asMap(homeC['team']);
    final awayTeam = _asMap(awayC['team']);
    final statusType = _asMap(_asMap(comp['status'])['type']);
    final venueMap = _asMap(comp['venue']);
    final venueAddr = _asMap(venueMap['address']);
    final venueName = (venueMap['fullName'] ?? '').toString();
    final venueCity = (venueAddr['city'] ?? '').toString();
    final venue = [venueName, venueCity].where((s) => s.isNotEmpty).join(', ');

    return Fixture(
      id: _asInt(event['id']),
      sport: sport,
      date: _asDate(event['date']),
      leagueId: leagueId,
      leagueName: leagueName,
      leagueLogo: leagueLogo,
      countryCode: '',
      continent: '',
      statusText: (statusType['description'] ?? statusType['detail'] ?? '').toString(),
      status: MatchStatusMapper.fromEspn(statusType),
      venue: venue,
      homeTeamId: _asInt(homeTeam['id']),
      homeTeamName: (homeTeam['displayName'] ?? homeTeam['name'] ?? '').toString(),
      homeTeamLogo: (homeTeam['logo'] ?? '').toString(),
      awayTeamId: _asInt(awayTeam['id']),
      awayTeamName: (awayTeam['displayName'] ?? awayTeam['name'] ?? '').toString(),
      awayTeamLogo: (awayTeam['logo'] ?? '').toString(),
      homeScore: _asNullableInt(homeC['score']),
      awayScore: _asNullableInt(awayC['score']),
    );
  }

  factory Fixture.fromApiJson(
    Map<String, dynamic> j,
    String sport, {
    (String code, String continent) Function(String raw)? resolveCountry,
  }) {
    final base = (j['fixture'] ?? j['game'] ?? j) as Map;
    final league = _asMap(j['league']);
    final teams = _asMap(j['teams']);
    final goals = _asMap(j['goals'] ?? j['scores']);

    final rawCountry = league['country'];
    String raw = '';
    if (rawCountry is Map) {
      raw = (rawCountry['code'] ?? rawCountry['name'] ?? '').toString();
    } else if (rawCountry is String) {
      raw = rawCountry;
    }

    final resolved = resolveCountry?.call(raw) ?? (raw, '');

    final home = _asMap(teams['home']);
    final away = _asMap(teams['away']);
    final venueMap = _asMap(base['venue']);
    final venueName = (venueMap['name'] ?? '').toString();
    final venueCity = (venueMap['city'] ?? '').toString();
    final venue = [venueName, venueCity].where((s) => s.isNotEmpty).join(', ');

    return Fixture(
      id: _asInt(base['id']),
      sport: sport,
      date: _asDate(base['date']),
      leagueId: (league['id'] ?? '').toString(),
      leagueName: (league['name'] ?? '').toString(),
      leagueLogo: (league['logo'] ?? '').toString(),
      countryCode: resolved.$1,
      continent: resolved.$2,
      statusText: _asMap(base['status'])['long']?.toString() ?? '',
      status: MatchStatusMapper.fromApiFootball(
        _asMap(base['status'])['short']?.toString() ?? '',
      ),
      venue: venue,
      homeTeamId: _asInt(home['id']),
      homeTeamName: (home['name'] ?? '').toString(),
      homeTeamLogo: (home['logo'] ?? '').toString(),
      awayTeamId: _asInt(away['id']),
      awayTeamName: (away['name'] ?? '').toString(),
      awayTeamLogo: (away['logo'] ?? '').toString(),
      homeScore: _scoreFor(goals['home']),
      awayScore: _scoreFor(goals['away']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _asNullableInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime _asDate(dynamic v) {
  if (v is String) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
  return DateTime.now();
}

int? _scoreFor(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is Map) return _asNullableInt(v['total'] ?? v['score']);
  return null;
}

class FixtureAdapter extends TypeAdapter<Fixture> {
  @override
  final int typeId = 4;

  @override
  Fixture read(BinaryReader r) {
    return Fixture(
      id: r.readInt(),
      sport: r.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(r.readInt()),
      leagueId: r.readString(),
      leagueName: r.readString(),
      leagueLogo: r.readString(),
      countryCode: r.readString(),
      continent: r.readString(),
      statusText: r.readString(),
      status: MatchStatus.values[r.readInt()],
      venue: r.readString(),
      homeTeamId: r.readInt(),
      homeTeamName: r.readString(),
      homeTeamLogo: r.readString(),
      awayTeamId: r.readInt(),
      awayTeamName: r.readString(),
      awayTeamLogo: r.readString(),
      homeScore: r.readBool() ? r.readInt() : null,
      awayScore: r.readBool() ? r.readInt() : null,
    );
  }

  @override
  void write(BinaryWriter w, Fixture f) {
    w.writeInt(f.id);
    w.writeString(f.sport);
    w.writeInt(f.date.millisecondsSinceEpoch);
    w.writeString(f.leagueId);
    w.writeString(f.leagueName);
    w.writeString(f.leagueLogo);
    w.writeString(f.countryCode);
    w.writeString(f.continent);
    w.writeString(f.statusText);
    w.writeInt(f.status.index);
    w.writeString(f.venue);
    w.writeInt(f.homeTeamId);
    w.writeString(f.homeTeamName);
    w.writeString(f.homeTeamLogo);
    w.writeInt(f.awayTeamId);
    w.writeString(f.awayTeamName);
    w.writeString(f.awayTeamLogo);
    w.writeBool(f.homeScore != null);
    if (f.homeScore != null) w.writeInt(f.homeScore!);
    w.writeBool(f.awayScore != null);
    if (f.awayScore != null) w.writeInt(f.awayScore!);
  }
}
