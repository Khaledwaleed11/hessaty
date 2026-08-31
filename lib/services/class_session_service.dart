import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';

enum ClassStatus { notStarted, running, ended }

class ClassSessionService {
  static const String boxName = 'classSessions';

  static Box? _box;

  static Future<Box> _getBox() async {
    if (_box != null) {
      return _box!;
    }

    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
    } else {
      _box = await Hive.openBox(boxName);
    }

    return _box!;
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _sessionKey(ClassScheduleModel schedule, DateTime date) {
    return '${schedule.id}_${_dateKey(date)}';
  }

  static TimeOfDay? _parseTime(String value) {
    final cleaned = value.trim().toUpperCase();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM|ص|م)?$',
    ).firstMatch(cleaned);

    if (match == null) {
      return null;
    }

    var hour = int.tryParse(match.group(1) ?? '') ?? 0;

    final minute = int.tryParse(match.group(2) ?? '') ?? 0;

    final period = match.group(3);

    if ((period == 'AM' || period == 'ص') && hour == 12) {
      hour = 0;
    }

    if ((period == 'PM' || period == 'م') && hour != 12) {
      hour += 12;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  static DateTime _todayWithTime(TimeOfDay time) {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  static Future<bool> isManuallyEnded(ClassScheduleModel schedule) async {
    final box = await _getBox();

    final key = _sessionKey(schedule, DateTime.now());

    final value = box.get(key);

    return value is Map && value['isEnded'] == true;
  }

  static Future<void> markEnded(ClassScheduleModel schedule) async {
    final box = await _getBox();
    final now = DateTime.now();

    final key = _sessionKey(schedule, now);

    await box.put(key, {
      'scheduleId': schedule.id,
      'date': _dateKey(now),
      'isEnded': true,
      'endedAt': now.toIso8601String(),
    });
  }

  static Future<ClassStatus> getStatus(ClassScheduleModel schedule) async {
    final manuallyEnded = await isManuallyEnded(schedule);

    if (manuallyEnded) {
      return ClassStatus.ended;
    }

    final start = _parseTime(schedule.startTime);

    final end = _parseTime(schedule.endTime);

    if (start == null || end == null) {
      return ClassStatus.notStarted;
    }

    final now = DateTime.now();

    final startDate = _todayWithTime(start);

    final endDate = _todayWithTime(end);

    if (now.isBefore(startDate)) {
      return ClassStatus.notStarted;
    }

    if (now.isAfter(endDate) || now.isAtSameMomentAs(endDate)) {
      await markEnded(schedule);
      return ClassStatus.ended;
    }

    return ClassStatus.running;
  }
}
