class LevelModel {
  final String id;
  final String name;
  final double monthlyFee;

  const LevelModel({
    required this.id,
    required this.name,
    required this.monthlyFee,
  });

  factory LevelModel.fromJson(Map<dynamic, dynamic> json) {
    return LevelModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      monthlyFee: double.tryParse(
        json['monthlyFee']?.toString() ?? '',
      ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyFee': monthlyFee,
    };
  }

  LevelModel copyWith({
    String? id,
    String? name,
    double? monthlyFee,
  }) {
    return LevelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyFee: monthlyFee ?? this.monthlyFee,
    );
  }
}