import 'package:hive_flutter/hive_flutter.dart';

import '../models/sport.dart';
import '../models/continent.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../models/match_details.dart';
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
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(MatchDetailsAdapter());
}

const Duration _countriesTtl = Duration(days: 30);
const Duration _leaguesTtl = Duration(days: 7);

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

  const schemaVersion = 14;
  if (metaBox.get('schema_version') != schemaVersion) {
    await Hive.deleteBoxFromDisk('countries');
    await Hive.deleteBoxFromDisk('leagues');
    await Hive.deleteBoxFromDisk('sports');
    await Hive.deleteBoxFromDisk('continents');
    await Hive.deleteBoxFromDisk('match_details');
    await metaBox.delete('countries_synced_at');
    await metaBox.delete('leagues_synced_at');
    for (final name in const [
      'fixtures_football',
      'fixtures_american_football',
      'fixtures_basketball',
      'fixtures_hockey',
    ]) {
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
}

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
  } catch (e, st) {
    // ignore: avoid_print
    print('[db_init] _syncCountries failed: $e\n$st');
  }
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
  } catch (e, st) {
    // ignore: avoid_print
    print('[db_init] _syncLeagues failed: $e\n$st');
  }
}
