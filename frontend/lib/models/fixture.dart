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

  factory Fixture.fromJson(Map<String, dynamic> j) {
    return Fixture(
      id: _asInt(j['id']),
      sport: j['sport'] as String,
      date: _asDate(j['date']),
      leagueId: j['leagueId'] as String,
      leagueName: j['leagueName'] as String,
      leagueLogo: j['leagueLogo'] as String,
      countryCode: j['countryCode'] as String,
      continent: j['continent'] as String,
      statusText: j['statusText'] as String,
      status: MatchStatusMapper.fromBackend(j['status'] as String),
      venue: j['venue'] as String,
      homeTeamId: _asInt(j['homeTeamId']),
      homeTeamName: j['homeTeamName'] as String,
      homeTeamLogo: j['homeTeamLogo'] as String,
      awayTeamId: _asInt(j['awayTeamId']),
      awayTeamName: j['awayTeamName'] as String,
      awayTeamLogo: j['awayTeamLogo'] as String,
      homeScore: _asNullableInt(j['homeScore']),
      awayScore: _asNullableInt(j['awayScore']),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _asNullableInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime _asDate(dynamic v) {
  if (v is String) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
  return DateTime.now();
}

