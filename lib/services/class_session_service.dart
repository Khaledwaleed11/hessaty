import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';

enum ClassStatus { notStarted, running, ended }

class ClassSessionService {
  static const String boxName = 'classSessions';

  static Box? _box;

  // ============================================================
  // Hive
  // ============================================================

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

  // ============================================================
  // Date Helpers
  // ============================================================

  static String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _sessionKey(
      ClassScheduleModel schedule,
      DateTime date,
      ) {
    return '${schedule.id}_${_dateKey(date)}';
  }

  // ============================================================
  // Hessaty Weekday
  //
  // Saturday = 1
  // Sunday   = 2
  // Monday   = 3
  // Tuesday  = 4
  // Wednesday= 5
  // Thursday = 6
  // Friday   = 7
  // ============================================================

  static int hessatyWeekday(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 1;

      case DateTime.sunday:
        return 2;

      case DateTime.monday:
        return 3;

      case DateTime.tuesday:
        return 4;

      case DateTime.wednesday:
        return 5;

      case DateTime.thursday:
        return 6;

      case DateTime.friday:
        return 7;

      default:
        return 1;
    }
  }

  // ============================================================
  // Check Today
  // ============================================================

  static bool isTodaySchedule(ClassScheduleModel schedule) {
    final today = DateTime.now();

    return hessatyWeekday(today) == schedule.weekday;
  }

  // ============================================================
  // Time
  // ============================================================

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

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  static DateTime _dateWithTime(
      DateTime date,
      TimeOfDay time,
      ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // ============================================================
  // Manual Session State
  // ============================================================

  static Future<bool> isManuallyEnded(
      ClassScheduleModel schedule,
      ) async {
    final box = await _getBox();

    final today = DateTime.now();

    /*
     * مهم جدًا:
     *
     * Session مرتبطة بالـ schedule + التاريخ.
     *
     * مثال:
     *
     * Monday 01/09
     * session key = scheduleId_2026-09-01
     *
     * Tuesday 02/09
     * session key = scheduleId_2026-09-02
     *
     * وبالتالي Session بتاعة الاثنين
     * لا يمكن أن تؤثر على الثلاثاء.
     */

    final key = _sessionKey(
      schedule,
      today,
    );

    final value = box.get(key);

    return value is Map && value['isEnded'] == true;
  }

  static Future<void> markEnded(
      ClassScheduleModel schedule,
      ) async {
    final box = await _getBox();

    final now = DateTime.now();

    final key = _sessionKey(
      schedule,
      now,
    );

    await box.put(
      key,
      {
        'scheduleId': schedule.id,
        'date': _dateKey(now),
        'isEnded': true,
        'endedAt': now.toIso8601String(),
      },
    );
  }

  // ============================================================
  // Status
  // ============================================================

  static Future<ClassStatus> getStatus(
      ClassScheduleModel schedule,
      ) async {
    final now = DateTime.now();

    final todayWeekday = hessatyWeekday(now);

    /*
     * ==========================================================
     * أهم قاعدة:
     *
     * الحصة مرتبطة بيوم معين من الأسبوع.
     *
     * لو اليوم الحالي مش هو يوم الحصة:
     *
     * => الحصة غير متاحة اليوم.
     *
     * ومهم جدًا إننا نعمل return هنا
     * قبل حساب الوقت.
     *
     * مثال:
     *
     * الحصة:
     * الاثنين 3:00 PM
     *
     * النهارده:
     * الثلاثاء
     *
     * النتيجة:
     * notStarted
     *
     * ولكنها ليست Session مفتوحة للتعديل.
     * ==========================================================
     */

    if (todayWeekday != schedule.weekday) {
      return ClassStatus.notStarted;
    }

    /*
     * ==========================================================
     * من هنا إحنا متأكدين إن:
     *
     * اليوم الحالي == يوم الحصة
     *
     * وبالتالي نقدر نتعامل مع Session اليوم.
     * ==========================================================
     */

    final manuallyEnded = await isManuallyEnded(schedule);

    if (manuallyEnded) {
      return ClassStatus.ended;
    }

    final start = _parseTime(schedule.startTime);

    final end = _parseTime(schedule.endTime);

    if (start == null || end == null) {
      return ClassStatus.notStarted;
    }

    final startDate = _dateWithTime(
      now,
      start,
    );

    final endDate = _dateWithTime(
      now,
      end,
    );

    // ==========================================================
    // قبل بداية الحصة
    // ==========================================================

    if (now.isBefore(startDate)) {
      return ClassStatus.notStarted;
    }

    // ==========================================================
    // بعد نهاية الحصة
    // ==========================================================

    if (now.isAfter(endDate) ||
        now.isAtSameMomentAs(endDate)) {
      await markEnded(schedule);

      return ClassStatus.ended;
    }

    // ==========================================================
    // أثناء الحصة
    // ==========================================================

    return ClassStatus.running;
  }
}