import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

enum DrillLevel { continent, country, league }

class Sport {
  static const Map<String, IconData> _icons = {
    'football': Icons.sports_soccer,
    'american_football': Icons.sports_football,
    'basketball': Icons.sports_basketball,
    'hockey': Icons.sports_hockey,
  };

  static const Map<String, List<DrillLevel>> _drillPaths = {
    'football': [DrillLevel.continent, DrillLevel.country, DrillLevel.league],
    'american_football': [DrillLevel.league],
    'basketball': [DrillLevel.league],
    'hockey': [DrillLevel.league],
  };

  final String id;
  final String name;
  final String iconKey;

  Sport({required this.name, required this.iconKey, String? id})
      : id = id ?? name;

  Icon get icon => Icon(_icons[iconKey] ?? Icons.sports);

  List<DrillLevel> get drillPath => _drillPaths[id] ?? const [];
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
