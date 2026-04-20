import 'package:hive/hive.dart';

class League {
  final String id;
  final String name;
  final String logo;
  final String type;
  final String sportId;
  final String? countryId;

  League({
    required this.id,
    required this.name,
    required this.logo,
    required this.type,
    required this.sportId,
    this.countryId,
  });

  factory League.fromJson(Map<String, dynamic> j) {
    return League(
      id: j['id'] as String,
      name: j['name'] as String,
      logo: j['logo'] as String,
      type: j['type'] as String,
      sportId: j['sportId'] as String,
      countryId: j['countryId'] as String?,
    );
  }
}

class LeagueAdapter extends TypeAdapter<League> {
  @override
  final int typeId = 1;

  @override
  League read(BinaryReader r) => League(
        id: r.readString(),
        name: r.readString(),
        logo: r.readString(),
        type: r.readString(),
        sportId: r.readString(),
        countryId: r.readBool() ? r.readString() : null,
      );

  @override
  void write(BinaryWriter w, League obj) {
    w.writeString(obj.id);
    w.writeString(obj.name);
    w.writeString(obj.logo);
    w.writeString(obj.type);
    w.writeString(obj.sportId);
    w.writeBool(obj.countryId != null);
    if (obj.countryId != null) w.writeString(obj.countryId!);
  }
}
