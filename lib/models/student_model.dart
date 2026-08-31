class StudentModel {
  final String id;
  final String name;
  final String phone;
  final String parentPhone;
  final String grade;
  final String groupId;
  final String scheduleId;
  final String notes;
  final DateTime registrationDate;

  const StudentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.parentPhone,
    required this.grade,
    required this.groupId,
    required this.scheduleId,
    required this.notes,
    required this.registrationDate,
  });

  factory StudentModel.fromJson(Map<dynamic, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      parentPhone: json['parentPhone']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      scheduleId: json['scheduleId']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      registrationDate:
          DateTime.tryParse(json['registrationDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'parentPhone': parentPhone,
      'grade': grade,
      'groupId': groupId,
      'scheduleId': scheduleId,
      'notes': notes,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? parentPhone,
    String? grade,
    String? groupId,
    String? scheduleId,
    String? notes,
    DateTime? registrationDate,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      grade: grade ?? this.grade,
      groupId: groupId ?? this.groupId,
      scheduleId: scheduleId ?? this.scheduleId,
      notes: notes ?? this.notes,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }
}
