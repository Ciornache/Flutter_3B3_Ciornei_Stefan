import 'package:hive/hive.dart';

import 'stat_row.dart';
import 'match_play.dart';

export 'stat_row.dart';
export 'match_play.dart';

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
