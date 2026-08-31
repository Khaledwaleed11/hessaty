import 'package:hive_flutter/hive_flutter.dart';

import '../models/attendance_model.dart';

class AttendanceService {
  static const String boxName = 'attendance';

  static Box get _box => Hive.box(boxName);

  static Future<void> saveAttendance(AttendanceModel attendance) async {
    await _box.put(attendance.id, attendance.toJson());
  }

  static Future<List<AttendanceModel>> getAttendance() async {
    final attendance = <AttendanceModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        attendance.add(
          AttendanceModel.fromJson(Map<dynamic, dynamic>.from(value)),
        );
      } catch (_) {}
    }

    return attendance;
  }

  static Future<List<AttendanceModel>> getAttendanceForClass(
    String scheduleId,
    DateTime date,
  ) async {
    final allAttendance = await getAttendance();

    return allAttendance
        .where(
          (item) =>
              item.scheduleId == scheduleId && _isSameDay(item.date, date),
        )
        .toList();
  }

  static Future<List<AttendanceModel>> getStudentAttendance(
    String studentId,
  ) async {
    final allAttendance = await getAttendance();

    return allAttendance.where((item) => item.studentId == studentId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<AttendanceModel?> getAttendanceRecord(
    String studentId,
    String scheduleId,
    DateTime date,
  ) async {
    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        final attendance = AttendanceModel.fromJson(
          Map<dynamic, dynamic>.from(value),
        );

        if (attendance.studentId == studentId &&
            attendance.scheduleId == scheduleId &&
            _isSameDay(attendance.date, date)) {
          return attendance;
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<void> removeAttendance(String attendanceId) async {
    await _box.delete(attendanceId);
  }

  static Future<void> clearAttendance() async {
    await _box.clear();
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
