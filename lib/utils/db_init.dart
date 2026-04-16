import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sport.dart';
import '../models/continent.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../services/api_service.dart';
import '../models/fixture.dart';

final List<Sport> sports = [
  Sport(name: 'Football', iconKey: 'soccer'),
  Sport(name: 'Nfl', iconKey: 'nfl'),
  Sport(name: 'Afl', iconKey: 'afl'),
  Sport(name: 'Hockey', iconKey: 'hockey'),
];

final List<Continent> continents = [
  Continent(name: 'Europe', emoji: '🇪🇺'),
  Continent(name: 'Asia', emoji: '🌏'),
  Continent(name: 'Africa', emoji: '🌍'),
  Continent(name: 'North America', emoji: '🌎'),
  Continent(name: 'South America', emoji: '🌎'),
  Continent(name: 'Antarctica', emoji: '🧊'),
];

final Map<String, String> countryContinentMap = {
  'GB': 'Europe',
  'FR': 'Europe',
  'DE': 'Europe',
  'IT': 'Europe',
  'ES': 'Europe',
  'PT': 'Europe',
  'NL': 'Europe',
  'BE': 'Europe',
  'CH': 'Europe',
  'AT': 'Europe',
  'PL': 'Europe',
  'CZ': 'Europe',
  'SE': 'Europe',
  'NO': 'Europe',
  'DK': 'Europe',
  'FI': 'Europe',
  'RU': 'Europe',
  'UA': 'Europe',
  'GR': 'Europe',
  'TR': 'Europe',
  'RO': 'Europe',
  'BG': 'Europe',
  'HR': 'Europe',
  'HU': 'Europe',
  'SK': 'Europe',
  'SI': 'Europe',
  'IE': 'Europe',
  'IS': 'Europe',
  'LU': 'Europe',
  'MT': 'Europe',
  'CY': 'Europe',
  'AL': 'Europe',
  'BA': 'Europe',
  'RS': 'Europe',
  'ME': 'Europe',
  'MK': 'Europe',
  'BY': 'Europe',
  'MD': 'Europe',
  'LT': 'Europe',
  'LV': 'Europe',
  'EE': 'Europe',

  'JP': 'Asia',
  'CN': 'Asia',
  'IN': 'Asia',
  'KR': 'Asia',
  'TH': 'Asia',
  'VN': 'Asia',
  'MY': 'Asia',
  'SG': 'Asia',
  'ID': 'Asia',
  'PH': 'Asia',
  'BD': 'Asia',
  'PK': 'Asia',
  'IR': 'Asia',
  'IQ': 'Asia',
  'SA': 'Asia',
  'AE': 'Asia',
  'IL': 'Asia',
  'KZ': 'Asia',
  'UZ': 'Asia',
  'TJ': 'Asia',
  'AF': 'Asia',
  'KG': 'Asia',
  'TM': 'Asia',
  'HK': 'Asia',
  'TW': 'Asia',
  'MO': 'Asia',
  'MN': 'Asia',
  'KH': 'Asia',
  'LA': 'Asia',
  'MM': 'Asia',
  'BT': 'Asia',
  'NP': 'Asia',
  'LK': 'Asia',
  'MV': 'Asia',
  'QA': 'Asia',
  'BH': 'Asia',
  'KW': 'Asia',
  'OM': 'Asia',
  'YE': 'Asia',
  'JO': 'Asia',
  'LB': 'Asia',
  'SY': 'Asia',

  'ZA': 'Africa',
  'EG': 'Africa',
  'NG': 'Africa',
  'KE': 'Africa',
  'MA': 'Africa',
  'GH': 'Africa',
  'UG': 'Africa',
  'ET': 'Africa',
  'TZ': 'Africa',
  'SD': 'Africa',
  'DZ': 'Africa',
  'SN': 'Africa',
  'CI': 'Africa',
  'CM': 'Africa',
  'BW': 'Africa',
  'ZW': 'Africa',
  'MW': 'Africa',
  'MZ': 'Africa',
  'ZM': 'Africa',
  'RW': 'Africa',
  'BJ': 'Africa',
  'BF': 'Africa',
  'GA': 'Africa',
  'CG': 'Africa',
  'CD': 'Africa',
  'AO': 'Africa',
  'NA': 'Africa',
  'SC': 'Africa',
  'MU': 'Africa',
  'TN': 'Africa',
  'LY': 'Africa',
  'GM': 'Africa',
  'GW': 'Africa',
  'GN': 'Africa',
  'ML': 'Africa',
  'MR': 'Africa',
  'NE': 'Africa',
  'TG': 'Africa',
  'DJ': 'Africa',
  'SO': 'Africa',
  'ER': 'Africa',
  'SS': 'Africa',
  'CF': 'Africa',
  'TD': 'Africa',
  'CV': 'Africa',

  'US': 'North America',
  'CA': 'North America',
  'MX': 'North America',
  'CR': 'North America',
  'PA': 'North America',
  'BZ': 'North America',
  'GT': 'North America',
  'HN': 'North America',
  'NI': 'North America',
  'SV': 'North America',
  'BS': 'North America',
  'JM': 'North America',
  'TT': 'North America',
  'CU': 'North America',
  'DO': 'North America',
  'HT': 'North America',

  'BR': 'South America',
  'AR': 'South America',
  'CO': 'South America',
  'PE': 'South America',
  'VE': 'South America',
  'CL': 'South America',
  'EC': 'South America',
  'BO': 'South America',
  'PY': 'South America',
  'UY': 'South America',
  'GY': 'South America',
  'SR': 'South America',

  'AQ': 'Antarctica',
};

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CountryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LeagueAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SportAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ContinentAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(FixtureAdapter());
}

const Map<String, String> fixtureBoxBySport = {
  'Football': 'fixtures_football',
  'Nfl': 'fixtures_nfl',
  'Afl': 'fixtures_afl',
  'Hockey': 'fixtures_hockey',
};

List<String> _fixtureEndpoints(String sport, List<String> dates) {
  final path = sport == 'Football' ? '/fixtures' : '/games';
  return dates.map((d) => '$path?date=$d').toList();
}

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
  print('Initializing Hive database');
  await Hive.initFlutter();
  _registerAdapters();
  print('Adapters registered');

  final metaBox = await Hive.openBox('meta');

  const schemaVersion = 5;
  if (metaBox.get('schema_version') != schemaVersion) {
    print('Schema version bump → clearing stale caches');
    final c = await Hive.openBox<Country>('countries');
    await c.clear();
    await metaBox.delete('countries_synced_at');
    for (final name in fixtureBoxBySport.values) {
      await Hive.deleteBoxFromDisk(name);
      await metaBox.delete('${name}_synced_at');
    }
    await metaBox.put('schema_version', schemaVersion);
  }

  final continentsBox = await Hive.openBox<Continent>('continents');
  if (continentsBox.isEmpty) {
    for (final c in continents) {
      await continentsBox.put(c.name, c);
    }
    print('Seeded ${continents.length} continents');
  }

  final sportsBox = await Hive.openBox<Sport>('sports');
  if (sportsBox.isEmpty) {
    for (final s in sports) {
      await sportsBox.put(s.id, s);
    }
    print('Seeded ${sports.length} sports');
  }

  final countryBox = await Hive.openBox<Country>('countries');
  final leagueBox = await Hive.openBox<League>('leagues');

  if (countryBox.isEmpty ||
      _isStale(metaBox, 'countries_synced_at', _countriesTtl)) {
    await _syncCountries(countryBox, metaBox);
  } else {
    print('Countries cache hit (${countryBox.length} items)');
  }

  if (leagueBox.isEmpty ||
      _isStale(metaBox, 'leagues_synced_at', _leaguesTtl)) {
    await _syncLeagues(leagueBox, metaBox);
  } else {
    print('Leagues cache hit (${leagueBox.length} items)');
  }

  final today = DateTime.now();
  final dates = [
    _fmtDate(today.subtract(const Duration(days: 1))),
    _fmtDate(today),
    _fmtDate(today.add(const Duration(days: 1))),
  ];

  for (final entry in fixtureBoxBySport.entries) {
    final sport = entry.key;
    final boxName = entry.value;
    final box = await Hive.openBox<Fixture>(boxName);
    final metaKey = '${boxName}_synced_at';

    if (box.isEmpty || _isStale(metaBox, metaKey, _fixturesTtl)) {
      await _syncFixturesForSport(sport, box, metaBox, metaKey, dates);
    } else {
      print('$sport fixtures cache hit (${box.length} items)');
    }
  }

  print('Database initialization complete');
}

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _syncCountries(Box<Country> box, Box meta) async {
  print('Fetching /countries');
  try {
    final response = await ApiService.get('/countries');
    if (response.statusCode != 200) {
      print(
        'Countries fetch failed (${response.statusCode}); keeping cached ${box.length} items',
      );
      return;
    }
    final json = jsonDecode(response.body);
    final list = (json['response'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    extendWithContinents(list);

    await box.clear();
    for (final c in list) {
      final country = Country.fromJson(c);
      await box.put(country.code, country);
    }
    await _markSynced(meta, 'countries_synced_at');
    print('Synced ${list.length} countries');
  } catch (e, st) {
    print('Countries sync error: $e\n$st');
  }
}

Future<void> _syncLeagues(Box<League> box, Box meta) async {
  print('Fetching /leagues');
  try {
    final response = await ApiService.get('/leagues');
    if (response.statusCode != 200) {
      print(
        'Leagues fetch failed (${response.statusCode}); keeping cached ${box.length} items',
      );
      return;
    }
    final json = jsonDecode(response.body);
    final list = (json['response'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    await box.clear();
    for (final l in list) {
      final league = League.fromJson(l);
      await box.put(league.id, league);
    }
    await _markSynced(meta, 'leagues_synced_at');
    print('Synced ${list.length} leagues');
  } catch (e, st) {
    print('Leagues sync error: $e\n$st');
  }
}

Future<void> _syncFixturesForSport(
  String sport,
  Box<Fixture> box,
  Box meta,
  String metaKey,
  List<String> dates,
) async {
  final countryBox = await Hive.openBox<Country>('countries');
  final byName = <String, Country>{};
  final byCode = <String, Country>{};
  for (final c in countryBox.values) {
    byName[c.name] = c;
    byCode[c.code] = c;
  }
  (String, String) resolveCountry(String raw) {
    final c = byCode[raw] ?? byName[raw];
    if (c != null) return (c.code, c.continent);
    return (raw, countryContinentMap[raw] ?? '');
  }

  final endpoints = _fixtureEndpoints(sport, dates);
  if (endpoints.isEmpty) {
    print('No endpoints configured for $sport');
    return;
  }

  await box.clear();
  var totalFetched = 0;
  var anyFailed = false;

  for (final endpoint in endpoints) {
    print('Fetching $sport $endpoint');
    try {
      final response = await ApiService.get(endpoint, sport: sport);
      if (response.statusCode != 200) {
        anyFailed = true;
        print('$sport $endpoint failed (${response.statusCode})');
        continue;
      }
      final json = jsonDecode(response.body);
      print(
        json['response'] is List
            ? '$sport $endpoint returned ${json['response'].length} items'
            : '$sport $endpoint returned a non-list response',
      );
      final list = (json['response'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (final f in list) {
        final fixture = Fixture.fromApiJson(
          f,
          sport,
          resolveCountry: resolveCountry,
        );
        await box.put(fixture.id, fixture);
      }
      totalFetched += list.length;
      print('Fetched ${list.length} $sport fixtures from $endpoint');
    } catch (e, st) {
      anyFailed = true;
      print('$sport $endpoint sync error: $e\n$st');
    }
  }

  if (!anyFailed) {
    await _markSynced(meta, metaKey);
  }
  print(
    'Synced $totalFetched $sport fixtures across ${endpoints.length} request(s)',
  );
}

void extendWithContinents(List<Map<String, dynamic>> countries) {
  for (final country in countries) {
    final code = country['code'];
    if (code is String && countryContinentMap.containsKey(code)) {
      print(
        'Extending country ${country['name']} with continent ${countryContinentMap[code]}',
      );
      country['continent'] = countryContinentMap[code];
    }
  }
}
