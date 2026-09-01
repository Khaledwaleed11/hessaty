class ClassScheduleModel {
  final String id;
  final String groupId;
  final int weekday;
  final String startTime;
  final String endTime;
  final String lessonTitle;
  final String grade;

  const ClassScheduleModel({
    required this.id,
    required this.groupId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.lessonTitle,
    required this.grade,
  });

  factory ClassScheduleModel.fromJson(Map<dynamic, dynamic> json) {
    return ClassScheduleModel(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      lessonTitle: json['lessonTitle']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'weekday': weekday,
      'startTime': startTime,
      'endTime': endTime,
      'lessonTitle': lessonTitle,
      'grade': grade,
    };
  }

  ClassScheduleModel copyWith({
    String? id,
    String? groupId,
    int? weekday,
    String? startTime,
    String? endTime,
    String? lessonTitle,
    String? grade,
  }) {
    return ClassScheduleModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      grade: grade ?? this.grade,
    );
  }
}