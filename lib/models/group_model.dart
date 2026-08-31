class GroupModel {
  final String id;
  final String name;
  final String grade;
  final int weekday;

  const GroupModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.weekday,
  });

  factory GroupModel.fromJson(Map<dynamic, dynamic> json) {
    return GroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'grade': grade, 'weekday': weekday};
  }

  GroupModel copyWith({String? id, String? name, String? grade, int? weekday}) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      weekday: weekday ?? this.weekday,
    );
  }
}
