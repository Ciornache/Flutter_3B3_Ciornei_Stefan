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
    final code = json['code'] as String;
    return Country(
      id: (json['id'] as String?) ?? code,
      name: json['name'] as String,
      code: code,
      flag: json['flag'] as String,
      continent: json['continent'] as String,
    );
  }
}

class CountryAdapter extends TypeAdapter<Country> {
  @override
  final int typeId = 0;

  @override
  Country read(BinaryReader r)
  {
    final id = r.readString();
    final name = r.readString();
    final code = r.readString();
    final flag = r.readString();
    final continent = r.readString();
    return Country(
      id: id,
      name: name,
      code: code,
      flag: flag,
      continent: continent,
    );
  }

  @override
  void write(BinaryWriter w, Country obj) {
    w.writeString(obj.id);
    w.writeString(obj.name);
    w.writeString(obj.code);
    w.writeString(obj.flag);
    w.writeString(obj.continent);
  }
}
