import 'package:hive_flutter/hive_flutter.dart';

import '../models/student_model.dart';

class StudentService {
  static const String boxName = 'students';

  static Box get _box => Hive.box(boxName);

  /// إضافة طالب جديد
  static Future<void> addStudent(StudentModel student) async {
    await _box.put(student.id, student.toJson());
  }

  /// تعديل بيانات طالب
  static Future<void> updateStudent(StudentModel student) async {
    await _box.put(student.id, student.toJson());
  }

  /// جلب كل الطلاب
  static Future<List<StudentModel>> getStudents() async {
    final students = <StudentModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        students.add(StudentModel.fromJson(Map<dynamic, dynamic>.from(value)));
      } catch (_) {
        // تجاهل أي سجل غير صالح
      }
    }

    return students;
  }

  /// جلب الطلاب حسب المجموعة
  static Future<List<StudentModel>> getStudentsByGroup(String groupId) async {
    final students = await getStudents();

    return students.where((student) => student.groupId == groupId).toList();
  }

  /// جلب الطلاب حسب الحصة / الموعد
  static Future<List<StudentModel>> getStudentsBySchedule(
    String scheduleId,
  ) async {
    final students = await getStudents();

    return students
        .where((student) => student.scheduleId == scheduleId)
        .toList();
  }

  /// جلب طالب حسب الـ ID
  static Future<StudentModel?> getStudentById(String studentId) async {
    final value = _box.get(studentId);

    if (value is! Map) {
      return null;
    }

    try {
      return StudentModel.fromJson(Map<dynamic, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  /// حذف طالب
  static Future<void> removeStudent(String studentId) async {
    await _box.delete(studentId);
  }

  /// حذف كل الطلاب
  static Future<void> clearStudents() async {
    await _box.clear();
  }
}
