enum MatchStatus { upcoming, live, finished }

extension MatchStatusMapper on MatchStatus {
  static MatchStatus fromBackend(String raw) {
    switch (raw.toLowerCase()) {
      case 'live':
        return MatchStatus.live;
      case 'finished':
        return MatchStatus.finished;
      case 'upcoming':
      case 'postponed':
      case 'cancelled':
      case 'unknown':
      default:
        return MatchStatus.upcoming;
    }
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
