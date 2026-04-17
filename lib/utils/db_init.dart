import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sport.dart';
import '../models/continent.dart';
import '../models/country.dart';
import '../models/league.dart';
import '../models/match_details.dart';
import '../services/api_service.dart';
import '../services/espn_service.dart';
import '../models/fixture.dart';

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
  Continent(name: 'Antarctica', emoji: '🧊'),
];

class _EspnLeagueSeed {
  final String id;
  final String name;
  final String sportId;
  final String logo;
  const _EspnLeagueSeed({
    required this.id,
    required this.name,
    required this.sportId,
    required this.logo,
  });
}

const String _espnLogoBase = 'https://a.espncdn.com/i/teamlogos/leagues/500';

const List<_EspnLeagueSeed> _espnLeagueSeeds = [
  _EspnLeagueSeed(id: 'nba', name: 'NBA', sportId: 'basketball', logo: '$_espnLogoBase/nba.png'),
  _EspnLeagueSeed(id: 'wnba', name: 'WNBA', sportId: 'basketball', logo: '$_espnLogoBase/wnba.png'),
  _EspnLeagueSeed(id: 'mens-college-basketball', name: 'NCAA Men\'s Basketball', sportId: 'basketball', logo: '$_espnLogoBase/ncaa.png'),
  _EspnLeagueSeed(id: 'womens-college-basketball', name: 'NCAA Women\'s Basketball', sportId: 'basketball', logo: '$_espnLogoBase/ncaa.png'),
  _EspnLeagueSeed(id: 'nbl', name: 'NBL (Australia)', sportId: 'basketball', logo: '$_espnLogoBase/nbl.png'),

  _EspnLeagueSeed(id: 'nfl', name: 'NFL', sportId: 'american_football', logo: '$_espnLogoBase/nfl.png'),
  _EspnLeagueSeed(id: 'college-football', name: 'NCAA Football', sportId: 'american_football', logo: '$_espnLogoBase/ncaa.png'),

  _EspnLeagueSeed(id: 'nhl', name: 'NHL', sportId: 'hockey', logo: '$_espnLogoBase/nhl.png'),
  _EspnLeagueSeed(id: 'mens-college-hockey', name: 'NCAA Men\'s Hockey', sportId: 'hockey', logo: '$_espnLogoBase/ncaa.png'),
  _EspnLeagueSeed(id: 'womens-college-hockey', name: 'NCAA Women\'s Hockey', sportId: 'hockey', logo: '$_espnLogoBase/ncaa.png'),
];

final Map<String, String> countryContinentMap = {
  'GB': 'Europe', 'FR': 'Europe', 'DE': 'Europe', 'IT': 'Europe', 'ES': 'Europe',
  'PT': 'Europe', 'NL': 'Europe', 'BE': 'Europe', 'CH': 'Europe', 'AT': 'Europe',
  'PL': 'Europe', 'CZ': 'Europe', 'SE': 'Europe', 'NO': 'Europe', 'DK': 'Europe',
  'FI': 'Europe', 'RU': 'Europe', 'UA': 'Europe', 'GR': 'Europe', 'TR': 'Europe',
  'RO': 'Europe', 'BG': 'Europe', 'HR': 'Europe', 'HU': 'Europe', 'SK': 'Europe',
  'SI': 'Europe', 'IE': 'Europe', 'IS': 'Europe', 'LU': 'Europe', 'MT': 'Europe',
  'CY': 'Europe', 'AL': 'Europe', 'BA': 'Europe', 'RS': 'Europe', 'ME': 'Europe',
  'MK': 'Europe', 'BY': 'Europe', 'MD': 'Europe', 'LT': 'Europe', 'LV': 'Europe',
  'EE': 'Europe',

  'JP': 'Asia', 'CN': 'Asia', 'IN': 'Asia', 'KR': 'Asia', 'TH': 'Asia',
  'VN': 'Asia', 'MY': 'Asia', 'SG': 'Asia', 'ID': 'Asia', 'PH': 'Asia',
  'BD': 'Asia', 'PK': 'Asia', 'IR': 'Asia', 'IQ': 'Asia', 'SA': 'Asia',
  'AE': 'Asia', 'IL': 'Asia', 'KZ': 'Asia', 'UZ': 'Asia', 'TJ': 'Asia',
  'AF': 'Asia', 'KG': 'Asia', 'TM': 'Asia', 'HK': 'Asia', 'TW': 'Asia',
  'MO': 'Asia', 'MN': 'Asia', 'KH': 'Asia', 'LA': 'Asia', 'MM': 'Asia',
  'BT': 'Asia', 'NP': 'Asia', 'LK': 'Asia', 'MV': 'Asia', 'QA': 'Asia',
  'BH': 'Asia', 'KW': 'Asia', 'OM': 'Asia', 'YE': 'Asia', 'JO': 'Asia',
  'LB': 'Asia', 'SY': 'Asia',

  'ZA': 'Africa', 'EG': 'Africa', 'NG': 'Africa', 'KE': 'Africa', 'MA': 'Africa',
  'GH': 'Africa', 'UG': 'Africa', 'ET': 'Africa', 'TZ': 'Africa', 'SD': 'Africa',
  'DZ': 'Africa', 'SN': 'Africa', 'CI': 'Africa', 'CM': 'Africa', 'BW': 'Africa',
  'ZW': 'Africa', 'MW': 'Africa', 'MZ': 'Africa', 'ZM': 'Africa', 'RW': 'Africa',
  'BJ': 'Africa', 'BF': 'Africa', 'GA': 'Africa', 'CG': 'Africa', 'CD': 'Africa',
  'AO': 'Africa', 'NA': 'Africa', 'SC': 'Africa', 'MU': 'Africa', 'TN': 'Africa',
  'LY': 'Africa', 'GM': 'Africa', 'GW': 'Africa', 'GN': 'Africa', 'ML': 'Africa',
  'MR': 'Africa', 'NE': 'Africa', 'TG': 'Africa', 'DJ': 'Africa', 'SO': 'Africa',
  'ER': 'Africa', 'SS': 'Africa', 'CF': 'Africa', 'TD': 'Africa', 'CV': 'Africa',

  'US': 'North America', 'CA': 'North America', 'MX': 'North America',
  'CR': 'North America', 'PA': 'North America', 'BZ': 'North America',
  'GT': 'North America', 'HN': 'North America', 'NI': 'North America',
  'SV': 'North America', 'BS': 'North America', 'JM': 'North America',
  'TT': 'North America', 'CU': 'North America', 'DO': 'North America',
  'HT': 'North America',

  'BR': 'South America', 'AR': 'South America', 'CO': 'South America',
  'PE': 'South America', 'VE': 'South America', 'CL': 'South America',
  'EC': 'South America', 'BO': 'South America', 'PY': 'South America',
  'UY': 'South America', 'GY': 'South America', 'SR': 'South America',

  'AQ': 'Antarctica',
};

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CountryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LeagueAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SportAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ContinentAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(FixtureAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(MatchDetailsAdapter());
}

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
  print('Initializing Hive database');
  await Hive.initFlutter();
  _registerAdapters();
  print('Adapters registered');

  final metaBox = await Hive.openBox('meta');

  // To remove in final version

  const schemaVersion = 10;
  if (metaBox.get('schema_version') != schemaVersion) {
    print('Schema version bump → clearing stale caches');
    await Hive.deleteBoxFromDisk('countries');
    await Hive.deleteBoxFromDisk('leagues');
    await Hive.deleteBoxFromDisk('sports');
    await Hive.deleteBoxFromDisk('match_details');
    await metaBox.delete('countries_synced_at');
    await metaBox.delete('leagues_synced_at');
    const oldBoxes = ['fixtures_football', 'fixtures_nfl', 'fixtures_afl', 'fixtures_hockey'];
    for (final name in oldBoxes) {
      await Hive.deleteBoxFromDisk(name);
      await metaBox.delete('${name}_synced_at');
    }
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
    today.subtract(const Duration(days: 1)),
    today,
    today.add(const Duration(days: 1)),
  ];

  for (final entry in fixtureBoxBySport.entries) {
    final sportId = entry.key;
    final boxName = entry.value;
    final box = await Hive.openBox<Fixture>(boxName);
    final metaKey = '${boxName}_synced_at';

    if (box.isEmpty || _isStale(metaBox, metaKey, _fixturesTtl)) {
      if (sportId == 'football') {
        await _syncFootballFixtures(box, metaBox, metaKey, dates);
      } else {
        await _syncEspnFixtures(sportId, box, metaBox, metaKey, dates);
      }
    } else {
      print('$sportId fixtures cache hit (${box.length} items)');
    }
  }

  print('Database initialization complete');
}

String _fmtIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _syncCountries(Box<Country> box, Box meta) async {
  print('Fetching /countries');
  try {
    final response = await ApiService.get('/countries');
    if (response.statusCode != 200) {
      print('Countries fetch failed (${response.statusCode}); keeping cached ${box.length} items');
      return;
    }
    final json = jsonDecode(response.body);
    final list = (json['response'] as List<dynamic>).cast<Map<String, dynamic>>();
    extendWithContinents(list);

    await box.clear();
    for (final c in list) {
      final country = Country.fromJson(c);
      await box.put(country.code, country);
    }
    await box.put('World', Country(
      id: 'World',
      name: 'World',
      code: 'World',
      flag: '',
      continent: 'World',
    ));
    await _markSynced(meta, 'countries_synced_at');
    print('Synced ${list.length} countries (+ World)');
  } catch (e, st) {
    print('Countries sync error: $e\n$st');
  }
}

Future<void> _syncLeagues(Box<League> box, Box meta) async {
  await box.clear();
  await _seedEspnLeagues(box);
  await _syncFootballLeagues(box, meta);
}

Future<void> _seedEspnLeagues(Box<League> box) async {
  for (final seed in _espnLeagueSeeds) {
    await box.put(seed.id, League(
      id: seed.id,
      name: seed.name,
      logo: seed.logo,
      type: 'League',
      sportId: seed.sportId,
      countryId: null,
    ));
  }
  print('Seeded ${_espnLeagueSeeds.length} ESPN leagues');
}

Future<void> _syncFootballLeagues(Box<League> box, Box meta) async {
  print('Fetching /leagues');
  try {
    final response = await ApiService.get('/leagues');
    if (response.statusCode != 200) {
      print('Leagues fetch failed (${response.statusCode}); keeping cached ${box.length} items');
      return;
    }
    final json = jsonDecode(response.body);
    final list = (json['response'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (final l in list) {
      final league = League.fromApiFootballJson(l);
      await box.put(league.id, league);
    }
    await _markSynced(meta, 'leagues_synced_at');
    print('Synced ${list.length} football leagues');
  } catch (e, st) {
    print('Football leagues sync error: $e\n$st');
  }
}

Future<void> _syncFootballFixtures(
  Box<Fixture> box,
  Box meta,
  String metaKey,
  List<DateTime> dates,
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

  await box.clear();
  var totalFetched = 0;
  var anyFailed = false;

  for (final date in dates) {
    final endpoint = '/fixtures?date=${_fmtIsoDate(date)}';
    print('Fetching football $endpoint');
    try {
      final response = await ApiService.get(endpoint, sport: 'football');
      if (response.statusCode != 200) {
        anyFailed = true;
        print('football $endpoint failed (${response.statusCode})');
        continue;
      }
      final json = jsonDecode(response.body);
      final list = (json['response'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final f in list) {
        final fixture = Fixture.fromApiJson(f, 'football', resolveCountry: resolveCountry);
        await box.put(fixture.id, fixture);
      }
      totalFetched += list.length;
      print('Fetched ${list.length} football fixtures from $endpoint');
    } catch (e, st) {
      anyFailed = true;
      print('football $endpoint sync error: $e\n$st');
    }
  }

  if (!anyFailed) await _markSynced(meta, metaKey);
  print('Synced $totalFetched football fixtures');
}

Future<void> _syncEspnFixtures(
  String sportId,
  Box<Fixture> box,
  Box meta,
  String metaKey,
  List<DateTime> dates,
) async {
  final leagueBox = await Hive.openBox<League>('leagues');
  final leagues = leagueBox.values.where((l) => l.sportId == sportId).toList();
  if (leagues.isEmpty) {
    print('No leagues for $sportId');
    return;
  }

  await box.clear();
  var totalFetched = 0;
  var anyFailed = false;

  for (final league in leagues) {
    for (final date in dates) {
      try {
        final response = await EspnService.scoreboard(
          sportId: sportId,
          leagueSlug: league.id,
          date: EspnService.formatDate(date),
        );
        if (response.statusCode != 200) {
          anyFailed = true;
          print('$sportId/${league.id} ${_fmtIsoDate(date)} failed (${response.statusCode})');
          continue;
        }
        final json = jsonDecode(response.body);
        final events = (json['events'] as List?) ?? const [];
        for (final e in events) {
          final fixture = Fixture.fromEspnJson(
            (e as Map).cast<String, dynamic>(),
            sportId,
            leagueId: league.id,
            leagueName: league.name,
            leagueLogo: league.logo,
          );
          await box.put(fixture.id, fixture);
        }
        totalFetched += events.length;
      } catch (e, st) {
        anyFailed = true;
        print('$sportId/${league.id} ${_fmtIsoDate(date)} sync error: $e\n$st');
      }
    }
  }

  if (!anyFailed) await _markSynced(meta, metaKey);
  print('Synced $totalFetched $sportId fixtures across ${leagues.length} league(s)');
}

void extendWithContinents(List<Map<String, dynamic>> countries) {
  for (final country in countries) {
    final code = country['code'];
    if (code is String && countryContinentMap.containsKey(code)) {
      country['continent'] = countryContinentMap[code];
    }
  }
}
