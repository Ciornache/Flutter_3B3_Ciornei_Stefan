import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:country_flags/country_flags.dart';
import '../models/country.dart';
import '../models/sport.dart';
import '../models/continent.dart';
import '../models/league.dart';
import '../models/fixture.dart';
import '../utils/db_init.dart' show fixtureBoxBySport;
import '../widgets/fixture_card.dart';
import 'match_detail_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 20;

  late TabController _tabController;

  List<dynamic> _drawerElements = [];
  final Map<String, String> _filters = {};
  List<Fixture> _currentFixtures = [];
  Map<String, Country> _countryByCode = {};
  Sport? _selectedSport;
  bool _skippedCountry = false;

  int _level = 0;
  final List<int> _pages = [0, 0, 0];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadDrawerElements();
    _loadCountryLookup();
    _reloadFixtures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _activeSport => _filters['sport'];
  String? get _activeContinent => _filters['continent'];
  String? get _activeCountry => _filters['country'];
  String? get _activeLeague => _filters['league'];

  DrillLevel? _drillLevelAt(int level) {
    if (level == 0) return null;
    final path = _selectedSport?.drillPath ?? const [];
    final idx = level - 1;
    if (idx < 0 || idx >= path.length) return null;
    return path[idx];
  }

  String _filterKeyAt(int level) {
    if (level == 0) return 'sport';
    return _drillLevelAt(level)?.name ?? '';
  }

  int get _maxLevel => 1 + (_selectedSport?.drillPath.length ?? 0) - 1;

  Future<void> _loadCountryLookup() async {
    final box = await Hive.openBox<Country>('countries');
    setState(() {
      _countryByCode = {for (final c in box.values) c.code: c};
    });
  }

  Future<List<dynamic>> _openBoxValues(int level) async {
    if (level == 0) {
      return (await Hive.openBox<Sport>('sports')).values.toList();
    }
    final drill = _drillLevelAt(level);
    switch (drill) {
      case DrillLevel.continent:
        return (await Hive.openBox<Continent>('continents')).values.toList();
      case DrillLevel.country:
        return (await Hive.openBox<Country>('countries')).values.toList();
      case DrillLevel.league:
        return (await Hive.openBox<League>('leagues')).values.toList();
      case null:
        return const [];
    }
  }

  Future<void> _loadDrawerElements() async {
    List<dynamic> items = await _openBoxValues(_level);
    final drill = _drillLevelAt(_level);

    if (drill == DrillLevel.country) {
      final continent = _activeContinent;
      if (continent != null) {
        items = items
            .where((c) => c is Country && c.continent == continent)
            .toList();
      }
    } else if (drill == DrillLevel.league) {
      final sportId = _activeSport;
      final countryCode = _activeCountry;
      items = items.where((l) {
        if (l is! League) return false;
        if (sportId != null && l.sportId != sportId) return false;
        if (countryCode != null && l.countryId != countryCode) return false;
        return true;
      }).toList();
    }

    setState(() {
      _drawerElements = items;
    });
  }

  Future<void> _reloadFixtures() async {
    final sportId = _activeSport;
    final List<Fixture> all = [];

    if (sportId != null) {
      final boxName = fixtureBoxBySport[sportId];
      if (boxName != null) {
        final box = await Hive.openBox<Fixture>(boxName);
        all.addAll(box.values);
      }
    } else {
      for (final boxName in fixtureBoxBySport.values) {
        final box = await Hive.openBox<Fixture>(boxName);
        all.addAll(box.values);
      }
    }

    final continent = _activeContinent;
    final country = _activeCountry;
    final league = _activeLeague;

    final filtered = all.where((f) {
      if (country != null && f.countryCode != country) return false;
      if (league != null && f.leagueId != league) return false;
      if (continent != null) {
        final c = _countryByCode[f.countryCode];
        if (c == null || c.continent.toLowerCase() != continent.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _currentFixtures = filtered;
      for (var i = 0; i < _pages.length; i++) {
        _pages[i] = 0;
      }
    });
  }

  String _filterValueOf(dynamic element) {
    if (element is Sport) return element.id;
    if (element is Continent) return element.name;
    if (element is Country) return element.code;
    if (element is League) return element.id;
    return element.toString();
  }

  void _onElementTap(dynamic element) {
    final key = _filterKeyAt(_level);
    final value = _filterValueOf(element);
    _filters[key] = value;
    print('Drawer forward: added filter $key=$value');

    if (_level == 0 && element is Sport) {
      _selectedSport = element;
    }

    if (element is Continent && element.name == 'World') {
      _filters['country'] = 'World';
      _skippedCountry = true;
      final path = _selectedSport?.drillPath ?? const [];
      final leagueIdx = path.indexOf(DrillLevel.league);
      if (leagueIdx >= 0) {
        _level = 1 + leagueIdx;
        _loadDrawerElements();
        _reloadFixtures();
        return;
      }
    }

    if (_level < _maxLevel) {
      _level++;
      _loadDrawerElements();
    } else {
      setState(() {});
    }
    _reloadFixtures();
  }

  void _deactivateLeague() {
    _filters.remove('league');
    _reloadFixtures();
  }

  void _goBack() {
    if (_skippedCountry && _drillLevelAt(_level) == DrillLevel.league) {
      _filters.remove('league');
      _filters.remove('country');
      _filters.remove('continent');
      _skippedCountry = false;
      final path = _selectedSport?.drillPath ?? const [];
      final continentIdx = path.indexOf(DrillLevel.continent);
      _level = continentIdx >= 0 ? 1 + continentIdx : 1;
      _loadDrawerElements();
      _reloadFixtures();
      return;
    }
    if (_filters.isNotEmpty) {
      final lastKey = _filters.keys.last;
      _filters.remove(lastKey);
      print('Drawer back: removed filter $lastKey');
    }
    if (_level > 0) _level--;
    if (_level == 0) _selectedSport = null;
    _loadDrawerElements();
    _reloadFixtures();
  }

  Widget buildImage(dynamic element) {
    if (element is Sport) return element.icon;
    if (element is Continent) return Text(element.emoji);
    if (element is Country) {
      return CountryFlag.fromCountryCode(
        element.code,
        theme: const ImageTheme(shape: Circle()),
      );
    }
    if (element is League) {
      return Image.network(
        element.logo,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      );
    }
    return const Icon(Icons.error);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Fixture> _fixturesForTab(int tabIndex) {
    final now = DateTime.now();
    final target = tabIndex == 0
        ? now.subtract(const Duration(days: 1))
        : tabIndex == 1
        ? now
        : now.add(const Duration(days: 1));
    return _currentFixtures.where((f) => _sameDay(f.date, target)).toList();
  }

  Widget _buildFixtureList(int tabIndex) {
    final fixtures = _fixturesForTab(tabIndex);
    if (fixtures.isEmpty) {
      return const Center(child: Text('No matches'));
    }

    final totalPages = (fixtures.length / _pageSize).ceil();
    final page = _pages[tabIndex].clamp(0, totalPages - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, fixtures.length);
    final pageItems = fixtures.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: pageItems.length,
            itemBuilder: (_, i) => FixtureCard(
              fixture: pageItems[i],
              sportFilterActive: _activeSport != null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(fixture: pageItems[i]),
                ),
              ),
            ),
          ),
        ),
        _paginationBar(tabIndex, page, totalPages, fixtures.length),
      ],
    );
  }

  Widget _paginationBar(int tabIndex, int page, int totalPages, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 0
                ? () => setState(() => _pages[tabIndex] = page - 1)
                : null,
          ),
          Text('Page ${page + 1} of $totalPages  ($total)'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages - 1
                ? () => setState(() => _pages[tabIndex] = page + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Yesterday'),
            Tab(text: 'Today'),
            Tab(text: 'Tomorrow'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, _buildFixtureList),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            if (_level > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Back'),
                onTap: _goBack,
              ),
            if (_drawerElements.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ..._drawerElements.map((element) {
                final isActiveLeague =
                    element is League && _activeLeague == element.id;
                return ListTile(
                  selected: isActiveLeague,
                  selectedTileColor: Colors.blue.shade100,
                  title: Text(element?.name ?? element.toString()),
                  trailing: buildImage(element),
                  onTap: () {
                    if (isActiveLeague) {
                      _deactivateLeague();
                    } else {
                      _onElementTap(element);
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
