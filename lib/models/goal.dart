class Goal {
  int homeScore;
  int awayScore;
  Goal({required this.homeScore, required this.awayScore});

  factory Goal.fromJson( Map<String, dynamic> json) {
    return Goal(
      homeScore: json['home'] ?? 0,
      awayScore: json['away'] ?? 0,
    );
  }

}
