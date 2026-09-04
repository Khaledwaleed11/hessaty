import 'package:hive_flutter/hive_flutter.dart';

import '../models/level_model.dart';

class LevelService {
  static const String boxName = 'levels';

  static Box get _box => Hive.box(boxName);

  static Future<void> addLevel(LevelModel level) async {
    await _box.put(
      level.id,
      level.toJson(),
    );
  }

  static Future<void> updateLevel(LevelModel level) async {
    await _box.put(
      level.id,
      level.toJson(),
    );
  }

  static Future<List<LevelModel>> getLevels() async {
    final levels = <LevelModel>[];

    for (final value in _box.values) {
      if (value is! Map) continue;

      try {
        levels.add(
          LevelModel.fromJson(
            Map<dynamic, dynamic>.from(value),
          ),
        );
      } catch (_) {}
    }

    return levels;
  }

  static Future<LevelModel?> getLevelById(
      String levelId,
      ) async {
    final value = _box.get(levelId);

    if (value is! Map) {
      return null;
    }

    try {
      return LevelModel.fromJson(
        Map<dynamic, dynamic>.from(value),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeLevel(
      String levelId,
      ) async {
    await _box.delete(levelId);
  }

  static Future<void> clearLevels() async {
    await _box.clear();
  }
}