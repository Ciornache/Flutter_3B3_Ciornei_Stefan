import 'goal.dart';

class Score {
  Goal ?halftime;
  Goal ?fulltime;
  Goal ?extratime;
  Goal ?penalty;
  Score({this.halftime, this.fulltime, this.extratime, this.penalty});
  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      halftime: json['halftime'] != null ? Goal.fromJson(json['halftime']) : null,
      fulltime: json['fulltime'] != null ? Goal.fromJson(json['fulltime']) : null,
      extratime: json['extratime'] != null ? Goal.fromJson(json['extratime']) : null,
      penalty: json['penalty'] != null ? Goal.fromJson(json['penalty']) : null,
    );
  }
}
