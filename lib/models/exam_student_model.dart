class ExamStudentModel {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final double? mark;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ExamStudentModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.mark,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamStudentModel.fromJson(Map<dynamic, dynamic> json) {
    final markValue = json['mark'];

    double? parsedMark;

    if (markValue != null) {
      parsedMark = double.tryParse(markValue.toString());
    }

    return ExamStudentModel(
      id: json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      mark: parsedMark,
      createdAt:
      DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'examId': examId,
      'studentId': studentId,
      'studentName': studentName,
      'mark': mark,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ExamStudentModel copyWith({
    String? id,
    String? examId,
    String? studentId,
    String? studentName,
    double? mark,
    bool clearMark = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamStudentModel(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      mark: clearMark ? null : (mark ?? this.mark),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}