class ClassScheduleModel {
  final String id;
  final String groupId;
  final String levelId;
  final int weekday;
  final String startTime;
  final String endTime;
  final String lessonTitle;
  final String grade;

  const ClassScheduleModel({
    required this.id,
    required this.groupId,
    required this.levelId,
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
      levelId: json['levelId']?.toString() ?? '',
      weekday: int.tryParse(
        json['weekday']?.toString() ?? '',
      ) ??
          1,
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
      'levelId': levelId,
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
    String? levelId,
    int? weekday,
    String? startTime,
    String? endTime,
    String? lessonTitle,
    String? grade,
  }) {
    return ClassScheduleModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      levelId: levelId ?? this.levelId,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      grade: grade ?? this.grade,
    );
  }
}