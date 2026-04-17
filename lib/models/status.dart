enum MatchStatus { upcoming, live, finished }

extension MatchStatusMapper on MatchStatus {
  static MatchStatus fromEspn(Map<String, dynamic> statusType) {
    final state = (statusType['state'] ?? '').toString();
    switch (state) {
      case 'in':
        return MatchStatus.live;
      case 'post':
        return MatchStatus.finished;
      default:
        return MatchStatus.upcoming;
    }
  }

  static MatchStatus fromApiFootball(String short) {
    const live = {'1H', 'HT', '2H', 'ET', 'BT', 'P', 'LIVE', 'SUSP', 'INT'};
    const finished = {'FT', 'AET', 'PEN', 'AWD', 'WO'};
    if (live.contains(short)) return MatchStatus.live;
    if (finished.contains(short)) return MatchStatus.finished;
    return MatchStatus.upcoming;
  }

  String get display {
    switch (this) {
      case MatchStatus.upcoming:
        return 'Upcoming';
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.finished:
        return 'Finished';
    }
  }
}
