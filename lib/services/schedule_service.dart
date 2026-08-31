import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';

class ScheduleService {
  static const String boxName = 'schedules';

  static Box get _box => Hive.box(boxName);

  static Future<void> addSchedule(ClassScheduleModel schedule) async {
    await _box.put(schedule.id, schedule.toJson());
  }

  static Future<void> updateSchedule(ClassScheduleModel schedule) async {
    await _box.put(schedule.id, schedule.toJson());
  }

  static Future<List<ClassScheduleModel>> getSchedules() async {
    final schedules = <ClassScheduleModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        schedules.add(
          ClassScheduleModel.fromJson(Map<dynamic, dynamic>.from(value)),
        );
      } catch (_) {}
    }

    schedules.sort((a, b) {
      final dayComparison = a.weekday.compareTo(b.weekday);

      if (dayComparison != 0) {
        return dayComparison;
      }

      return _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime));
    });

    return schedules;
  }

  static Future<List<ClassScheduleModel>> getSchedulesByDay(int weekday) async {
    final schedules = await getSchedules();

    return schedules.where((schedule) => schedule.weekday == weekday).toList();
  }

  static Future<List<ClassScheduleModel>> getSchedulesByGroup(
    String groupId,
  ) async {
    final schedules = await getSchedules();

    return schedules.where((schedule) => schedule.groupId == groupId).toList();
  }

  static Future<ClassScheduleModel?> getScheduleById(String scheduleId) async {
    final value = _box.get(scheduleId);

    if (value is! Map) {
      return null;
    }

    try {
      return ClassScheduleModel.fromJson(Map<dynamic, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeSchedule(String scheduleId) async {
    await _box.delete(scheduleId);
  }

  static Future<void> clearSchedules() async {
    await _box.clear();
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');

    if (parts.length < 2) {
      return 0;
    }

    final hour = int.tryParse(parts[0]) ?? 0;

    final minute = int.tryParse(parts[1]) ?? 0;

    return (hour * 60) + minute;
  }
}
