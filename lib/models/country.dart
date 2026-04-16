import 'package:hive/hive.dart';

class Country {
  final String id;
  final String name;
  final String code;
  final String flag;
  final String continent;

  Country({
    required this.id,
    required this.name,
    required this.code,
    required this.flag,
    required this.continent,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString();
    return Country(
      id: (json['id'] ?? code).toString(),
      name: (json['name'] ?? '').toString(),
      code: code,
      flag: (json['flag'] ?? '').toString(),
      continent: (json['continent'] ?? '').toString(),
    );
  }
}

class CountryAdapter extends TypeAdapter<Country> {
  @override
  final int typeId = 0;

  @override
  Country read(BinaryReader r) => Country(
        id: r.readString(),
        name: r.readString(),
        code: r.readString(),
        flag: r.readString(),
        continent: r.readString(),
      );

  @override
  void write(BinaryWriter w, Country obj) {
    w.writeString(obj.id);
    w.writeString(obj.name);
    w.writeString(obj.code);
    w.writeString(obj.flag);
    w.writeString(obj.continent);
  }
}
