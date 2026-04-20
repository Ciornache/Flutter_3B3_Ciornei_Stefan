import 'package:hive_flutter/hive_flutter.dart';

import '../models/sport.dart';
import '../models/continent.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../models/match_details.dart';
import '../models/fixture.dart';
import '../services/backend_service.dart';

final List<Sport> sports = [
  Sport(id: 'football', name: 'Football', iconKey: 'football'),
  Sport(id: 'american_football', name: 'American Football', iconKey: 'american_football'),
  Sport(id: 'basketball', name: 'Basketball', iconKey: 'basketball'),
  Sport(id: 'hockey', name: 'Hockey', iconKey: 'hockey'),
];

final List<Continent> continents = [
  Continent(name: 'World', emoji: '🌐'),
  Continent(name: 'Europe', emoji: '🇪🇺'),
  Continent(name: 'Asia', emoji: '🌏'),
  Continent(name: 'Africa', emoji: '🌍'),
  Continent(name: 'North America', emoji: '🌎'),
  Continent(name: 'South America', emoji: '🌎'),
  Continent(name: 'Oceania', emoji: '🌊'),
  Continent(name: 'Antarctica', emoji: '🧊'),
];

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CountryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LeagueAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SportAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ContinentAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(FixtureAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(MatchDetailsAdapter());
}

const List<String> _allSports = [
  'football',
  'american_football',
  'basketball',
  'hockey',
];

const Map<String, String> fixtureBoxBySport = {
  'football': 'fixtures_football',
  'american_football': 'fixtures_american_football',
  'basketball': 'fixtures_basketball',
  'hockey': 'fixtures_hockey',
};

const Duration _countriesTtl = Duration(days: 30);
const Duration _leaguesTtl = Duration(days: 7);
const Duration _fixturesTtl = Duration(days: 1);

bool _isStale(Box meta, String key, Duration ttl) {
  final raw = meta.get(key);
  if (raw is! String) return true;
  final last = DateTime.tryParse(raw);
  if (last == null) return true;
  return DateTime.now().difference(last) > ttl;
}

Future<void> _markSynced(Box meta, String key) =>
    meta.put(key, DateTime.now().toIso8601String());

Future<void> initializeDatabase() async {
  await Hive.initFlutter();
  _registerAdapters();

  final metaBox = await Hive.openBox('meta');

  const schemaVersion = 12;
  if (metaBox.get('schema_version') != schemaVersion) {
    await Hive.deleteBoxFromDisk('countries');
    await Hive.deleteBoxFromDisk('leagues');
    await Hive.deleteBoxFromDisk('sports');
    await Hive.deleteBoxFromDisk('continents');
    await Hive.deleteBoxFromDisk('match_details');
    await metaBox.delete('countries_synced_at');
    await metaBox.delete('leagues_synced_at');
    for (final name in fixtureBoxBySport.values) {
      await Hive.deleteBoxFromDisk(name);
      await metaBox.delete('${name}_synced_at');
    }
    await metaBox.put('schema_version', schemaVersion);
  }

  final continentsBox = await Hive.openBox<Continent>('continents');
  for (final c in continents) {
    await continentsBox.put(c.name, c);
  }

  final sportsBox = await Hive.openBox<Sport>('sports');
  for (final s in sports) {
    await sportsBox.put(s.id, s);
  }

  await Hive.openBox<bool>('watchlist');

  final countryBox = await Hive.openBox<Country>('countries');
  final leagueBox = await Hive.openBox<League>('leagues');

  if (countryBox.isEmpty ||
      _isStale(metaBox, 'countries_synced_at', _countriesTtl)) {
    await _syncCountries(countryBox, metaBox);
  }

  if (leagueBox.isEmpty ||
      _isStale(metaBox, 'leagues_synced_at', _leaguesTtl)) {
    await _syncLeagues(leagueBox, metaBox);
  }

  final today = DateTime.now();
  final dates = [
    today.subtract(const Duration(days: 1)),
    today,
    today.add(const Duration(days: 1)),
  ];

  for (final sportId in _allSports) {
    final boxName = fixtureBoxBySport[sportId]!;
    final box = await Hive.openBox<Fixture>(boxName);
    final metaKey = '${boxName}_synced_at';

    if (box.isEmpty || _isStale(metaBox, metaKey, _fixturesTtl)) {
      await _syncFixtures(sportId, box, metaBox, metaKey, dates);
    }
  }
}

String _fmtIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _syncCountries(Box<Country> box, Box meta) async {
  try {
    final data = await BackendService.getJson('/countries');
    final list = (data as List).cast<Map<String, dynamic>>();
    await box.clear();
    for (final c in list) {
      final country = Country.fromJson(c);
      await box.put(country.code.isNotEmpty ? country.code : country.id, country);
    }
    await _markSynced(meta, 'countries_synced_at');
  } catch (_) {}
}

Future<void> _syncLeagues(Box<League> box, Box meta) async {
  try {
    final data = await BackendService.getJson('/leagues');
    final list = (data as List).cast<Map<String, dynamic>>();
    await box.clear();
    for (final l in list) {
      final league = League.fromJson(l);
      await box.put(league.id, league);
    }
    await _markSynced(meta, 'leagues_synced_at');
  } catch (_) {}
}

Future<void> _syncFixtures(
  String sportId,
  Box<Fixture> box,
  Box meta,
  String metaKey,
  List<DateTime> dates,
) async {
  final datesParam = dates.map(_fmtIsoDate).join(',');
  try {
    final data = await BackendService.getJson(
      '/fixtures',
      query: {'sport': sportId, 'dates': datesParam},
    );
    final list = (data as List).cast<Map<String, dynamic>>();
    await box.clear();
    for (final f in list) {
      final fixture = Fixture.fromJson(f);
      await box.put(fixture.id, fixture);
    }
    await _markSynced(meta, metaKey);
  } catch (_) {}
}
