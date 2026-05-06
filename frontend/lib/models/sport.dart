import 'package:hive/hive.dart';

enum DrillLevel { continent, country, league }

class Sport {
  final String id;
  final String name;
  final String iconKey;

  Sport({required this.name, required this.iconKey, String? id})
      : id = id ?? name;
}

class SportAdapter extends TypeAdapter<Sport> {
  @override
  final int typeId = 2;

  @override
  Sport read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final iconKey = reader.readString();
    return Sport(id: id, name: name, iconKey: iconKey);
  }

  @override
  void write(BinaryWriter writer, Sport obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.iconKey);
  }
}
