import 'package:flutter/material.dart';
import '../models/fixture.dart';
import '../models/details/match_details.dart';
import '../models/status.dart';
import '../services/match_details_service.dart';
import '../services/watchlist_service.dart';
import '../widgets/match_overview.dart';

class MatchDetailScreen extends StatefulWidget {
  final Fixture fixture;

  const MatchDetailScreen({super.key, required this.fixture});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  MatchDetails? _details;
  bool _loading = false;
  late bool _watching;
  bool _togglingWatch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _watching = WatchlistService.isWatching(widget.fixture.id);
    _loadDetails();
  }

  Future<void> _toggleWatch() async {
    if (_togglingWatch) return;
    setState(() => _togglingWatch = true);
    try {
      await WatchlistService.toggle(widget.fixture.id);
      if (!mounted) return;
      setState(() => _watching = !_watching);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification toggle failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _togglingWatch = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    if (widget.fixture.status == MatchStatus.upcoming) return;
    setState(() => _loading = true);
    final d = await MatchDetailsService.load(widget.fixture);
    if (!mounted) return;
    setState(() {
      _details = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    final showTabs = f.status != MatchStatus.upcoming;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        actions: [
          if (f.status != MatchStatus.finished)
            IconButton(
              tooltip: _watching ? 'Unsubscribe from notifications' : 'Subscribe to notifications',
              onPressed: _togglingWatch ? null : _toggleWatch,
              icon: _togglingWatch
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _watching ? Icons.notifications_active : Icons.notifications_outlined,
                      color: _watching ? Colors.amber : null,
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          MatchOverview(fixture: f),
          if (!showTabs)
            const Expanded(
              child: Center(child: Text('Match has not started yet')),
            )
          else ...[
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Stats'),
                Tab(text: 'Play by Play'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _StatsTab(stats: _details?.stats ?? const []),
                        _PlaysTab(plays: _details?.plays ?? const []),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final List<StatRow> stats;
  const _StatsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(child: Text('No stats available'));
    }
    return ListView.separated(
      itemCount: stats.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = stats[i];
        return ListTile(
          title: Text(s.label, textAlign: TextAlign.center),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.home, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(s.away, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

class _PlaysTab extends StatelessWidget {
  final List<MatchPlay> plays;
  const _PlaysTab({required this.plays});

  @override
  Widget build(BuildContext context) {
    if (plays.isEmpty) {
      return const Center(child: Text('No play-by-play available'));
    }
    return ListView.separated(
      itemCount: plays.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = plays[i];
        final meta = [p.period, p.clock].where((s) => s.isNotEmpty).join(' · ');
        return ListTile(
          dense: true,
          leading: meta.isEmpty
              ? null
              : SizedBox(
                  width: 60,
                  child: Text(
                    meta,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
          title: Text(p.text, style: const TextStyle(fontSize: 13)),
        );
      },
    );
  }
}
