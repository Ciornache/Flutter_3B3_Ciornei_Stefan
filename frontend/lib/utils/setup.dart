import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sport.dart';
import '../models/continent.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../models/details/match_details.dart';
import '../services/backend_service.dart';

const Map<String, IconData> _sportIcons = {
  'football': Icons.sports_soccer,
  'american_football': Icons.sports_football,
  'basketball': Icons.sports_basketball,
  'hockey': Icons.sports_hockey,
  'baseball': Icons.sports_baseball,
};

const Map<String, List<DrillLevel>> _sportDrillPaths = {
  'football': [DrillLevel.continent, DrillLevel.country, DrillLevel.league],
  'american_football': [DrillLevel.league],
  'basketball': [DrillLevel.league],
  'hockey': [DrillLevel.league],
  'baseball': [DrillLevel.league],
};

Icon iconFor(Sport sport) =>
    Icon(_sportIcons[sport.iconKey] ?? Icons.sports);

List<DrillLevel> drillPathOf(Sport? sport) =>
    sport == null ? const [] : (_sportDrillPaths[sport.id] ?? const []);

final List<Sport> sports = [
  Sport(id: 'football', name: 'Football', iconKey: 'football'),
  Sport(id: 'american_football', name: 'American Football', iconKey: 'american_football'),
  Sport(id: 'basketball', name: 'Basketball', iconKey: 'basketball'),
  Sport(id: 'hockey', name: 'Hockey', iconKey: 'hockey'),
  Sport(id: 'baseball', name: 'Baseball', iconKey: 'baseball'),
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
    final list = ((await BackendService.get(
      '/countries',
      errorMessage: 'Failed to load countries',
    )) as List).cast<Map<String, dynamic>>();
    await box.clear();
    for (final c in list) {
      final country = Country.fromJson(c);
      await box.put(country.code.isNotEmpty ? country.code : country.id, country);
    }
    await _markSynced(meta, 'countries_synced_at');
  } catch (e, st) {
    // ignore: avoid_print
    print('[setup] _syncCountries failed: $e\n$st');
  }
}

Future<void> _syncLeagues(Box<League> box, Box meta) async {
  try {
    final list = ((await BackendService.get(
      '/leagues',
      errorMessage: 'Failed to load leagues',
    )) as List).cast<Map<String, dynamic>>();
    await box.clear();
    for (final l in list) {
      final league = League.fromJson(l);
      await box.put(league.id, league);
    }
    await _markSynced(meta, 'leagues_synced_at');
  } catch (e, st) {
    // ignore: avoid_print
    print('[setup] _syncLeagues failed: $e\n$st');
  }
}
