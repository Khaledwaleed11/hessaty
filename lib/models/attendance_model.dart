class AttendanceModel {
  final String id;
  final String studentId;
  final String scheduleId;
  final DateTime date;
  final bool isPresent;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.scheduleId,
    required this.date,
    required this.isPresent,
  });

  factory AttendanceModel.fromJson(Map<dynamic, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      scheduleId: json['scheduleId']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      isPresent: json['isPresent'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'scheduleId': scheduleId,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
    };
  }
  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? scheduleId,
    DateTime? date,
    bool? isPresent,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
    );
  }
}
