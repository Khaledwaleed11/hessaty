class GroupModel {
  final String id;
  final String name;
  final int weekday;

  const GroupModel({
    required this.id,
    required this.name,
    required this.weekday,
  });

  factory GroupModel.fromJson(Map<dynamic, dynamic> json) {
    return GroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      weekday: int.tryParse(json['weekday']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weekday': weekday,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    int? weekday,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      weekday: weekday ?? this.weekday,
    );
  }
}