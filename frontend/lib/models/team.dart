class Team {
  int id;
  String name;
  String code;

  Team({required this.id, required this.name, required this.code});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(id: json['id'], name: json['name'], code: json['code'] ?? '');
  }
}
