class PaymentModel {
  final String id;

  // الطالب
  final String studentId;

  // المجموعة
  final String groupId;

  // المستوى
  final String levelId;
  final String levelName;

  // قيمة المصاريف الشهرية وقت إنشاء السجل
  final double amount;

  // الشهر والسنة
  final int month;
  final int year;

  // حالة الدفع
  final bool isPaid;

  // تاريخ الدفع الفعلي
  final DateTime? paidAt;

  // تاريخ إنشاء سجل المصاريف
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.levelId,
    required this.levelName,
    required this.amount,
    required this.month,
    required this.year,
    required this.isPaid,
    required this.paidAt,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<dynamic, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      levelId: json['levelId']?.toString() ?? '',
      levelName: json['levelName']?.toString() ?? '',
      amount:
      double.tryParse(
        json['amount']?.toString() ?? '',
      ) ??
          0,
      month:
      int.tryParse(
        json['month']?.toString() ?? '',
      ) ??
          DateTime.now().month,
      year:
      int.tryParse(
        json['year']?.toString() ?? '',
      ) ??
          DateTime.now().year,
      isPaid: json['isPaid'] == true,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.tryParse(
        json['paidAt'].toString(),
      ),
      createdAt:
      DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'groupId': groupId,
      'levelId': levelId,
      'levelName': levelName,
      'amount': amount,
      'month': month,
      'year': year,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? studentId,
    String? groupId,
    String? levelId,
    String? levelName,
    double? amount,
    int? month,
    int? year,
    bool? isPaid,
    DateTime? paidAt,
    bool clearPaidAt = false,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      levelId: levelId ?? this.levelId,
      levelName: levelName ?? this.levelName,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      isPaid: isPaid ?? this.isPaid,
      paidAt: clearPaidAt
          ? null
          : (paidAt ?? this.paidAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}