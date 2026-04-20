import 'package:hive/hive.dart';

class Continent {
  final String name;
  final String emoji;

  Continent({required this.name, required this.emoji});
}

class ContinentAdapter extends TypeAdapter<Continent> {
  @override
  final int typeId = 3;

  @override
  Continent read(BinaryReader reader) {
    final name = reader.readString();
    final emoji = reader.readString();
    return Continent(name: name, emoji: emoji);
  }

  @override
  void write(BinaryWriter writer, Continent obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.emoji);
  }
}
