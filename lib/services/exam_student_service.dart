import 'package:hive_flutter/hive_flutter.dart';

import '../models/exam_student_model.dart';
import '../models/student_model.dart';

class ExamStudentService {
  static const String boxName = 'exam_students';

  static Box get _box => Hive.box(boxName);

  /// إضافة طالب إلى امتحان
  static Future<void> addExamStudent(
      ExamStudentModel examStudent,
      ) async {
    await _box.put(
      examStudent.id,
      examStudent.toJson(),
    );
  }

  /// إضافة مجموعة من الطلاب إلى امتحان
  static Future<void> addStudentsToExam({
    required String examId,
    required List<StudentModel> students,
  }) async {
    final now = DateTime.now();

    for (final student in students) {
      final id = '${examId}_${student.id}';

      final examStudent = ExamStudentModel(
        id: id,
        examId: examId,
        studentId: student.id,
        studentName: student.name,
        mark: null,
        createdAt: now,
        updatedAt: null,
      );

      await _box.put(
        id,
        examStudent.toJson(),
      );
    }
  }

  /// جلب كل طلاب امتحان معين
  static Future<List<ExamStudentModel>> getStudentsByExam(
      String examId,
      ) async {
    final students = <ExamStudentModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        final examStudent = ExamStudentModel.fromJson(
          Map<dynamic, dynamic>.from(value),
        );

        if (examStudent.examId == examId) {
          students.add(examStudent);
        }
      } catch (_) {}
    }

    students.sort(
          (a, b) => a.studentName
          .toLowerCase()
          .compareTo(b.studentName.toLowerCase()),
    );

    return students;
  }

  /// جلب طالب معين داخل امتحان
  static Future<ExamStudentModel?> getExamStudent(
      String examId,
      String studentId,
      ) async {
    final id = '${examId}_$studentId';

    final value = _box.get(id);

    if (value is! Map) {
      return null;
    }

    try {
      return ExamStudentModel.fromJson(
        Map<dynamic, dynamic>.from(value),
      );
    } catch (_) {
      return null;
    }
  }

  /// تسجيل / تعديل درجة الطالب
  static Future<void> updateMark({
    required String examId,
    required String studentId,
    required double mark,
  }) async {
    final id = '${examId}_$studentId';

    final value = _box.get(id);

    if (value is! Map) {
      return;
    }

    try {
      final current = ExamStudentModel.fromJson(
        Map<dynamic, dynamic>.from(value),
      );

      final updated = current.copyWith(
        mark: mark,
        updatedAt: DateTime.now(),
      );

      await _box.put(
        id,
        updated.toJson(),
      );
    } catch (_) {}
  }

  /// تعديل بيانات الطالب داخل الامتحان
  static Future<void> updateExamStudent(
      ExamStudentModel examStudent,
      ) async {
    await _box.put(
      examStudent.id,
      examStudent.toJson(),
    );
  }

  /// حذف طالب من امتحان
  static Future<void> removeExamStudent(
      String examStudentId,
      ) async {
    await _box.delete(examStudentId);
  }

  /// حذف كل طلاب امتحان معين
  static Future<void> removeStudentsByExam(
      String examId,
      ) async {
    final students = await getStudentsByExam(examId);

    for (final student in students) {
      await _box.delete(student.id);
    }
  }

  /// حذف كل بيانات طلاب الامتحانات
  static Future<void> clearExamStudents() async {
    await _box.clear();
  }
}