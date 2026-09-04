import 'package:hive_flutter/hive_flutter.dart';

import '../models/payment_model.dart';

class PaymentService {
  static const String boxName = 'payments';

  static Box get _box => Hive.box(boxName);

  static String buildPaymentId(
      String studentId,
      int year,
      int month,
      ) {
    return '${studentId}_${year}_${month.toString().padLeft(2, '0')}';
  }
  /// إضافة سجل مصاريف
  static Future<void> addPayment(
      PaymentModel payment,
      ) async {
    await _box.put(
      payment.id,
      payment.toJson(),
    );
  }

  /// تعديل سجل مصاريف
  static Future<void> updatePayment(
      PaymentModel payment,
      ) async {
    await _box.put(
      payment.id,
      payment.toJson(),
    );
  }

  /// جلب كل سجلات المصاريف
  static Future<List<PaymentModel>> getPayments() async {
    final payments = <PaymentModel>[];

    for (final value in _box.values) {
      if (value is! Map) {
        continue;
      }

      try {
        payments.add(
          PaymentModel.fromJson(
            Map<dynamic, dynamic>.from(value),
          ),
        );
      } catch (_) {
        // تجاهل أي سجل غير صالح
      }
    }

    return payments;
  }

  /// جلب مصاريف طالب معين
  static Future<List<PaymentModel>> getPaymentsByStudent(
      String studentId,
      ) async {
    final payments = await getPayments();

    return payments
        .where(
          (payment) => payment.studentId == studentId,
    )
        .toList();
  }

  /// جلب مصاريف مجموعة معينة
  static Future<List<PaymentModel>> getPaymentsByGroup(
      String groupId,
      ) async {
    final payments = await getPayments();

    return payments
        .where(
          (payment) => payment.groupId == groupId,
    )
        .toList();
  }

  /// جلب مصاريف مستوى معين
  static Future<List<PaymentModel>> getPaymentsByLevel(
      String levelId,
      ) async {
    final payments = await getPayments();

    return payments
        .where(
          (payment) => payment.levelId == levelId,
    )
        .toList();
  }

  /// جلب مصاريف شهر معين
  static Future<List<PaymentModel>> getPaymentsByMonth({
    required int month,
    required int year,
  }) async {
    final payments = await getPayments();

    return payments
        .where(
          (payment) =>
      payment.month == month &&
          payment.year == year,
    )
        .toList();
  }

  /// جلب مصاريف طالب في شهر معين
  static Future<PaymentModel?> getStudentPayment({
    required String studentId,
    required int month,
    required int year,
  }) async {
    final payments = await getPaymentsByStudent(
      studentId,
    );

    for (final payment in payments) {
      if (payment.month == month &&
          payment.year == year) {
        return payment;
      }
    }

    return null;
  }

  /// جلب مصاريف طالب في مستوى معين لشهر معين
  static Future<PaymentModel?> getStudentLevelPayment({
    required String studentId,
    required String levelId,
    required int month,
    required int year,
  }) async {
    final payments = await getPaymentsByStudent(
      studentId,
    );

    for (final payment in payments) {
      if (payment.levelId == levelId &&
          payment.month == month &&
          payment.year == year) {
        return payment;
      }
    }

    return null;
  }

  /// تغيير حالة الدفع
  static Future<void> updatePaymentStatus({
    required String paymentId,
    required bool isPaid,
  }) async {
    final value = _box.get(paymentId);

    if (value is! Map) {
      return;
    }

    try {
      final current = PaymentModel.fromJson(
        Map<dynamic, dynamic>.from(value),
      );

      final updated = current.copyWith(
        isPaid: isPaid,
        paidAt: isPaid ? DateTime.now() : null,
        clearPaidAt: !isPaid,
      );

      await _box.put(
        paymentId,
        updated.toJson(),
      );
    } catch (_) {
      // تجاهل أي سجل غير صالح
    }
  }

  /// حذف سجل مصاريف
  static Future<void> removePayment(
      String paymentId,
      ) async {
    await _box.delete(paymentId);
  }

  /// حذف كل سجلات المصاريف
  static Future<void> clearPayments() async {
    await _box.clear();
  }
}