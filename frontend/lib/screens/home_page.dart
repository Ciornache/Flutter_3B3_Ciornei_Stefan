import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:country_flags/country_flags.dart';
import '../models/country.dart';
import '../models/sport.dart';
import '../models/continent.dart';
import '../models/league.dart';
import '../models/fixture.dart';
import '../models/fixture_response.dart';
import '../services/backend_service.dart';
import '../services/device_service.dart';
import '../services/notification_service.dart';
import '../widgets/fixture_card.dart';
import '../widgets/pagination_bar.dart';
import '../utils/setup.dart';
import 'match_detail_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _drawerElements = [];
  final Map<String, String> _filters = {};
  Sport? _selectedSport;
  bool _skippedCountry = false;

  int _level = 0;
  bool _favouritesOn = false;
  final List<int> _pages = [0, 0, 0];
  final List<FixtureResponse?> _responses = [null, null, null];
  final List<bool> _loading = [false, false, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
      if (_responses[_tabController.index] == null) {
        _fetchResponse(_tabController.index);
      }
    });
    _loadDrawerElements();
    _fetchResponse(_tabController.index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.handleInitialMessage();
    });
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
  int get _maxLevel => 1 + drillPathOf(_selectedSport).length - 1;

  DateTime _tabDate(int tabIndex) {
    final now = DateTime.now();
    if (tabIndex == 0) return now.subtract(const Duration(days: 1));
    if (tabIndex == 2) return now.add(const Duration(days: 1));
    return now;
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DrillLevel? _drillLevelAt(int level) {
    if (level == 0) return null;
    final path = drillPathOf(_selectedSport);
    final idx = level - 1;
    if (idx < 0 || idx >= path.length) return null;
    return path[idx];
  }

  String _filterKeyAt(int level) {
    if (level == 0) return 'sport';
    return _drillLevelAt(level)?.name ?? '';
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
        items = items.where((c) => c.continent == continent).toList();
      }
    } else if (drill == DrillLevel.league) {
      final sportId = _activeSport;
      final countryCode = _activeCountry;
      items = items.where((l) {
        if (sportId != null && l.sportId != sportId) return false;
        if (countryCode != null && l.countryId != countryCode) return false;
        return true;
      }).toList();
    }
    setState(() {
      _drawerElements = items;
    });
  }

  Future<void> _fetchResponse(int tabIndex, {int? page}) async {
    final p = page ?? _pages[tabIndex];
    setState(() => _loading[tabIndex] = true);

    final query = <String, String>{
      'date': _isoDate(_tabDate(tabIndex)),
      'page': '$p',
    };
    if (_activeSport != null) query['sport'] = _activeSport!;
    if (_activeCountry != null) query['country'] = _activeCountry!;
    if (_activeContinent != null) query['continent'] = _activeContinent!;
    if (_activeLeague != null) query['league'] = _activeLeague!;
    if (_favouritesOn) {
      final deviceId = DeviceService.cachedDeviceId;
      if (deviceId != null) {
        query['favourites'] = 'true';
        query['deviceId'] = deviceId;
      }
    }

    try {
      final data = await BackendService.get(
        '/fixtures',
        query: query,
        errorMessage: 'Failed to load fixtures',
      );
      final resp = FixtureResponse.fromJson(data as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _responses[tabIndex] = resp;
        _pages[tabIndex] = resp.page;
        _loading[tabIndex] = false;
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('[home_page] _fetchResponse($tabIndex) failed: $e\n$st');
      if (!mounted) return;
      setState(() => _loading[tabIndex] = false);
    }
  }

  void _resetAllAndFetch() {
    for (var i = 0; i < 3; i++) {
      _responses[i] = null;
      _pages[i] = 0;
    }
    _fetchResponse(_tabController.index);
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

    if (_level == 0 && element is Sport) {
      _selectedSport = element;
    }

    if (element is Continent && element.name == 'World') {
      _filters['country'] = 'World';
      _skippedCountry = true;
      final path = drillPathOf(_selectedSport);
      _level = 1 + path.indexOf(DrillLevel.league);
      _loadDrawerElements();
      _resetAllAndFetch();
      return;
    }

    if (_level < _maxLevel) {
      _level++;
      _loadDrawerElements();
    } else {
      setState(() {});
    }
    _resetAllAndFetch();
  }

  void _goToPage(int tabIndex, int newPage) {
    setState(() => _pages[tabIndex] = newPage);
    _fetchResponse(tabIndex, page: newPage);
  }

  void _deactivateLeague() {
    _filters.remove('league');
    _fetchResponse(_tabController.index);
  }

  void _goBack() {
    if (_skippedCountry && _drillLevelAt(_level) == DrillLevel.league) {
      _filters.remove('league');
      _filters.remove('country');
      _filters.remove('continent');
      _skippedCountry = false;
      final path = drillPathOf(_selectedSport);
      final continentIdx = path.indexOf(DrillLevel.continent);
      _level = continentIdx >= 0 ? 1 + continentIdx : 1;
      _loadDrawerElements();
      _resetAllAndFetch();
      return;
    }
    if (_filters.isNotEmpty) {
      _filters.remove(_filters.keys.last);
    }
    if (_level > 0) _level--;
    if (_level == 0) _selectedSport = null;
    _loadDrawerElements();
    _resetAllAndFetch();
  }

  Widget buildImage(dynamic element) {
    if (element is Sport) return iconFor(element);
    if (element is Continent) return Text(element.emoji);
    if (element is Country) {
      return CountryFlag.fromCountryCode(
        element.code,
        theme: const ImageTheme(shape: Circle()),
      );
    }
    if (element is League) {
      if (element.logo.isEmpty) {
        return const Icon(Icons.emoji_events, size: 32);
      }
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

  Widget _buildEmptyState(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_score, size: 48, color: color),
          const SizedBox(height: 8),
          Text('No matches', style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildFixtureList(int tabIndex) {
    final resp = _responses[tabIndex];
    final loading = _loading[tabIndex];
    final fixtures = resp?.fixtures ?? const <Fixture>[];

    if (resp == null && loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (resp == null) {
      return _buildEmptyState(context);
    }

    final body = fixtures.isEmpty
        ? _buildEmptyState(context)
        : ListView.builder(
            itemCount: fixtures.length,
            itemBuilder: (_, i) => FixtureCard(
              fixture: fixtures[i],
              sportFilterActive: _activeSport != null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(fixture: fixtures[i]),
                ),
              ),
            ),
          );

    return Column(
      children: [
        Expanded(child: body),
        PaginationBar(
          page: _pages[tabIndex],
          totalPages: resp.totalPages,
          totalFixtures: resp.total,
          loading: loading,
          onPageChange: (newPage) => _goToPage(tabIndex, newPage),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _favouritesOn
                  ? Icons.notifications
                  : Icons.notifications_off_outlined,
            ),
            tooltip: 'Favourites',
            onPressed: () {
              setState(() => _favouritesOn = !_favouritesOn);
              _resetAllAndFetch();
            },
          ),
        ],
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: ListTile(
                    selected: isActiveLeague,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isActiveLeague
                          ? BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                    title: Text(
                      element?.name,
                      style: TextStyle(
                        fontWeight: isActiveLeague
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: buildImage(element),
                    onTap: () {
                      isActiveLeague
                          ? _deactivateLeague()
                          : _onElementTap(element);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
