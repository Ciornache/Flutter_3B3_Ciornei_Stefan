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
