import 'package:flutter/material.dart';
import '../models/fixture.dart';
import '../models/match_details.dart';
import '../models/status.dart';
import '../services/match_details_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetails();
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
      appBar: AppBar(title: const Text('Match Details')),
      body: Column(
        children: [
          _Header(fixture: f),
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

class _Header extends StatelessWidget {
  final Fixture fixture;
  const _Header({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _TeamBlock(
                  name: fixture.homeTeamName,
                  logo: fixture.homeTeamLogo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${fixture.homeScore ?? '-'}  :  ${fixture.awayScore ?? '-'}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _TeamBlock(
                  name: fixture.awayTeamName,
                  logo: fixture.awayTeamLogo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fixture.leagueName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (fixture.venue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fixture.venue,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 8),
          _StatusBadge(status: fixture.status),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String logo;
  const _TeamBlock({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (logo.isEmpty)
          const Icon(Icons.shield, size: 56, color: Colors.grey)
        else
          Image.network(
            logo,
            width: 56,
            height: 56,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.shield, size: 56, color: Colors.grey),
          ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MatchStatus.upcoming => Colors.blueGrey,
      MatchStatus.live => Colors.red,
      MatchStatus.finished => Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.display.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
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
