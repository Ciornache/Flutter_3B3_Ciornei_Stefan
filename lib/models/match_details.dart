import 'package:hive/hive.dart';

class StatRow {
  final String label;
  final String home;
  final String away;

  StatRow({required this.label, required this.home, required this.away});
}

class MatchPlay {
  final String text;
  final String period;
  final String clock;

  MatchPlay({required this.text, required this.period, required this.clock});
}

class MatchDetails {
  final int fixtureId;
  final List<StatRow> stats;
  final List<MatchPlay> plays;
  final DateTime fetchedAt;

  MatchDetails({
    required this.fixtureId,
    required this.stats,
    required this.plays,
    required this.fetchedAt,
  });
}

class MatchDetailsAdapter extends TypeAdapter<MatchDetails> {
  @override
  final int typeId = 5;

  @override
  MatchDetails read(BinaryReader r) {
    final fixtureId = r.readInt();
    final statCount = r.readInt();
    final stats = List<StatRow>.generate(statCount, (_) => StatRow(
          label: r.readString(),
          home: r.readString(),
          away: r.readString(),
        ));
    final playCount = r.readInt();
    final plays = List<MatchPlay>.generate(playCount, (_) => MatchPlay(
          text: r.readString(),
          period: r.readString(),
          clock: r.readString(),
        ));
    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(r.readInt());
    return MatchDetails(
      fixtureId: fixtureId,
      stats: stats,
      plays: plays,
      fetchedAt: fetchedAt,
    );
  }

  @override
  void write(BinaryWriter w, MatchDetails obj) {
    w.writeInt(obj.fixtureId);
    w.writeInt(obj.stats.length);
    for (final s in obj.stats) {
      w.writeString(s.label);
      w.writeString(s.home);
      w.writeString(s.away);
    }
    w.writeInt(obj.plays.length);
    for (final p in obj.plays) {
      w.writeString(p.text);
      w.writeString(p.period);
      w.writeString(p.clock);
    }
    w.writeInt(obj.fetchedAt.millisecondsSinceEpoch);
  }
}
