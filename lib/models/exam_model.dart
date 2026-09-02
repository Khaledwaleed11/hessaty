class ExamModel {
  final String id;
  final String title;
  final String groupId;
  final String scheduleId;
  final DateTime examDate;
  final double totalMarks;
  final double passingMarks;
  final DateTime createdAt;

  const ExamModel({
    required this.id,
    required this.title,
    required this.groupId,
    required this.scheduleId,
    required this.examDate,
    required this.totalMarks,
    required this.passingMarks,
    required this.createdAt,
  });

  factory ExamModel.fromJson(Map<dynamic, dynamic> json) {
    return ExamModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      scheduleId: json['scheduleId']?.toString() ?? '',
      examDate:
      DateTime.tryParse(json['examDate']?.toString() ?? '') ??
          DateTime.now(),
      totalMarks:
      double.tryParse(json['totalMarks']?.toString() ?? '') ?? 0,
      passingMarks:
      double.tryParse(json['passingMarks']?.toString() ?? '') ?? 0,
      createdAt:
      DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'groupId': groupId,
      'scheduleId': scheduleId,
      'examDate': examDate.toIso8601String(),
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ExamModel copyWith({
    String? id,
    String? title,
    String? groupId,
    String? scheduleId,
    DateTime? examDate,
    double? totalMarks,
    double? passingMarks,
    DateTime? createdAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      groupId: groupId ?? this.groupId,
      scheduleId: scheduleId ?? this.scheduleId,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}