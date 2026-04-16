enum FixtureStatus {
  notstarted,
  live,
  finished,
  halftime,
  extratime,
  penalty,
  breaktime,
}

extension FixtureStatusExtension on FixtureStatus {
  static FixtureStatus fromJson(String status) {
    switch (status) {
      case 'Not Started':
        return FixtureStatus.notstarted;
      case 'Live':
        return FixtureStatus.live;
      case 'Finished':
        return FixtureStatus.finished;
      case 'Halftime':
        return FixtureStatus.halftime;
      case 'Extra Time':
        return FixtureStatus.extratime;
      case 'Penalty':
        return FixtureStatus.penalty;
      case 'Break Time':
        return FixtureStatus.breaktime;
      default:
        throw Exception('Unknown fixture status: $status');
    }
  }
}