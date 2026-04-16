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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  static const List<String> _boxes = [
    'sports',
    'continents',
    'countries',
    'leagues',
  ];
  static const List<String> _filterKeys = [
    'sport',
    'continent',
    'country',
    'league',
  ];
  static const int _pageSize = 20;

  late TabController _tabController;

  List<dynamic> _drawerElements = [];
  final List<Map<String, dynamic>> _filters = [];
  List<Fixture> _currentFixtures = [];
  Map<String, Country> _countryByCode = {};

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

  String? get _activeSport => _filterValue('sport') as String?;
  String? get _activeContinent => _filterValue('continent') as String?;
  String? get _activeCountry => _filterValue('country') as String?;
  String? get _activeLeague => _filterValue('league')?.toString();

  dynamic _filterValue(String key) {
    print('Looking for filter $key in $_filters');
    for (final f in _filters) {
      if (f['filter'] == key) return f['value'];
    }
    return null;
  }

  Future<void> _loadCountryLookup() async {
    final box = await Hive.openBox<Country>('countries');
    setState(() {
      _countryByCode = {for (final c in box.values) c.code: c};
    });
  }

  Future<List<dynamic>> _openBoxValues(int level) async {
    switch (level) {
      case 0:
        return (await Hive.openBox<Sport>('sports')).values.toList();
      case 1:
        return (await Hive.openBox<Continent>('continents')).values.toList();
      case 2:
        return (await Hive.openBox<Country>('countries')).values.toList();
      case 3:
        return (await Hive.openBox<League>('leagues')).values.toList();
    }
    return const [];
  }

  Future<void> _loadDrawerElements() async {
    if (_level < 0 || _level >= _boxes.length) return;

    List<dynamic> items = await _openBoxValues(_level);

    if (_level == 2) {
      final continent = _activeContinent;
      if (continent != null) {
        items = items
            .where((c) => c is Country && c.continent == continent)
            .toList();
      }
    } else if (_level == 3) {
      final countryCode = _activeCountry;
      if (countryCode != null) {
        items = items
            .where((l) => l is League && l.countryId == countryCode)
            .toList();
      }
    }

    setState(() {
      _drawerElements = items;
    });
  }

  Future<void> _reloadFixtures() async {
    final sport = _activeSport;
    final List<Fixture> all = [];

    if (sport != null) {
      final boxName = fixtureBoxBySport[sport];
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
        print(
          'Filtering fixture ${f.id}: country=${f.countryCode} continent=${c?.continent} vs filter=$continent',
        );
        if (c == null || c.continent.toLowerCase() != continent.toLowerCase())
          return false;
      }
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    print(
      'Fixtures reloaded: ${filtered.length} of ${all.length} (sport=$sport)',
    );

    setState(() {
      _currentFixtures = filtered;
      for (var i = 0; i < _pages.length; i++) {
        _pages[i] = 0;
      }
    });
  }

  dynamic _filterValueOf(dynamic element) {
    if (element is Sport) return element.name;
    if (element is Continent) return element.name;
    if (element is Country) return element.code;
    if (element is League) return element.id;
    return element.toString();
  }

  String _nameOf(dynamic element) {
    if (element is Sport) return element.name;
    if (element is Continent) return element.name;
    if (element is Country) return element.name;
    if (element is League) return element.name;
    return element.toString();
  }

  void _onElementTap(dynamic element) {
    final filter = {
      'filter': _filterKeys[_level],
      'operator': r'$eq',
      'value': _filterValueOf(element),
    };
    _filters.add(filter);
    print('Drawer forward: added filter $filter');

    if (_level < _boxes.length - 1) {
      _level++;
      _loadDrawerElements();
    } else {
      setState(() {});
    }
    _reloadFixtures();
  }

  void _goBack() {
    if (_filters.isNotEmpty) {
      final removed = _filters.removeLast();
      print('Drawer back: removed filter $removed');
    }
    _level--;
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
            itemBuilder: (_, i) => FixtureCard(fixture: pageItems[i]),
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
              ..._drawerElements.map(
                (element) => ListTile(
                  title: Text(_nameOf(element)),
                  trailing: buildImage(element),
                  onTap: () => _onElementTap(element),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
