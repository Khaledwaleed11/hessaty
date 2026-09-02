import 'package:hive_flutter/hive_flutter.dart';

import '../models/exam_model.dart';

class ExamService {
  static const String boxName = 'exams';

  static Box get _box => Hive.box(boxName);

  /// إضافة امتحان
  static Future<void> addExam(ExamModel exam) async {
    await _box.put(exam.id, exam.toJson());
  }

  /// تعديل امتحان
  static Future<void> updateExam(ExamModel exam) async {
    await _box.put(exam.id, exam.toJson());
  }

  /// جلب كل الامتحانات
  static Future<List<ExamModel>> getExams() async {
    final exams = <ExamModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        exams.add(
          ExamModel.fromJson(
            Map<dynamic, dynamic>.from(value),
          ),
        );
      } catch (_) {}
    }

    exams.sort(
          (a, b) => b.examDate.compareTo(a.examDate),
    );

    return exams;
  }

  /// جلب امتحانات مجموعة معينة
  static Future<List<ExamModel>> getExamsByGroup(
      String groupId,
      ) async {
    final exams = await getExams();

    return exams
        .where((exam) => exam.groupId == groupId)
        .toList();
  }

  /// جلب امتحانات حصة معينة
  static Future<List<ExamModel>> getExamsBySchedule(
      String scheduleId,
      ) async {
    final exams = await getExams();

    return exams
        .where((exam) => exam.scheduleId == scheduleId)
        .toList();
  }

  /// جلب امتحان بالـ ID
  static Future<ExamModel?> getExamById(String examId) async {
    final value = _box.get(examId);

    if (value is! Map) {
      return null;
    }

    try {
      return ExamModel.fromJson(
        Map<dynamic, dynamic>.from(value),
      );
    } catch (_) {
      return null;
    }
  }

  /// حذف امتحان
  static Future<void> removeExam(String examId) async {
    await _box.delete(examId);
  }

  /// حذف كل الامتحانات
  static Future<void> clearExams() async {
    await _box.clear();
  }
}