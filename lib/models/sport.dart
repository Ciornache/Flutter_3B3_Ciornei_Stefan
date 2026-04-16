import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

class Sport {
  static const Map<String, IconData> _icons = {
    'soccer': Icons.sports_soccer,
    'basketball': Icons.sports_basketball,
    'tennis': Icons.sports_tennis,
    'baseball': Icons.sports_baseball,
    'hockey': Icons.sports_hockey,
  };

  final String id;
  final String name;
  final String iconKey;

  Sport({required this.name, required this.iconKey, String? id})
      : id = id ?? name;

  Icon get icon => Icon(_icons[iconKey] ?? Icons.sports);
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
