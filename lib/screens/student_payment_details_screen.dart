import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';
import '../models/level_model.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';

import '../services/level_service.dart';
import '../services/payment_service.dart';
import '../services/schedule_service.dart';

class StudentPaymentDetailsScreen extends StatefulWidget {
  final StudentModel student;

  const StudentPaymentDetailsScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentPaymentDetailsScreen> createState() =>
      _StudentPaymentDetailsScreenState();
}

class _StudentPaymentDetailsScreenState
    extends State<StudentPaymentDetailsScreen> {
  List<PaymentModel> _payments = [];

  LevelModel? _level;
  ClassScheduleModel? _schedule;

  bool _isLoading = true;

  late int _selectedYear;

  @override
  void initState() {
    super.initState();

    _selectedYear = DateTime.now().year;

    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final payments = await PaymentService.getPaymentsByStudent(
        widget.student.id,
      );

      final levels = await LevelService.getLevels();

      final schedules = await ScheduleService.getSchedules();

      ClassScheduleModel? schedule;

      try {
        schedule = schedules.firstWhere(
              (item) => item.id == widget.student.scheduleId,
        );
      } catch (_) {
        schedule = null;
      }

      LevelModel? level;

      /*
       * المستوى الأساسي يتم أخذه من الحصة.
       *
       * fallback على student.levelId فقط لدعم البيانات القديمة
       * التي تم حفظها قبل ربط المستوى بالحصة.
       */
      final scheduleLevelId = schedule?.levelId ?? '';

      final levelId = scheduleLevelId.isNotEmpty
          ? scheduleLevelId
          : widget.student.levelId;

      if (levelId.isNotEmpty) {
        try {
          level = levels.firstWhere(
                (item) => item.id == levelId,
          );
        } catch (_) {
          level = null;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = payments;
        _level = level;
        _schedule = schedule;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل بيانات الطالب: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // PAYMENT HELPERS
  // ============================================================

  PaymentModel? _getPaymentForMonth(
      int month,
      int year,
      ) {
    try {
      return _payments.firstWhere(
            (payment) =>
        payment.month == month &&
            payment.year == year,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isPaid(
      int month,
      int year,
      ) {
    final payment = _getPaymentForMonth(
      month,
      year,
    );

    return payment != null && payment.isPaid;
  }

  double _getAmount(
      int month,
      int year,
      ) {
    final payment = _getPaymentForMonth(
      month,
      year,
    );

    /*
     * لو الدفع تم بالفعل:
     * نستخدم المبلغ المحفوظ تاريخيًا.
     *
     * لو السجل موجود لكنه غير مدفوع:
     * نستخدم السعر الحالي للمستوى.
     *
     * ده مهم جدًا لو المدرس غير سعر المستوى.
     */
    if (payment != null && payment.isPaid) {
      return payment.amount;
    }

    return _level?.monthlyFee ?? 0;
  }

  // ============================================================
  // REGISTRATION DATE / DUE MONTHS
  // ============================================================

  int get _firstDueMonthForSelectedYear {
    final registrationDate =
        widget.student.registrationDate;

    /*
     * أي سنة قبل سنة تسجيل الطالب:
     * لا يوجد عليه أي مستحقات.
     */
    if (_selectedYear < registrationDate.year) {
      return 13;
    }

    /*
     * سنة تسجيل الطالب:
     * يبدأ الحساب من شهر التسجيل.
     */
    if (_selectedYear == registrationDate.year) {
      return registrationDate.month;
    }

    /*
     * السنوات بعد سنة التسجيل:
     * تبدأ من يناير.
     */
    return 1;
  }

  int get _lastDueMonthForSelectedYear {
    final now = DateTime.now();
    final registrationDate =
        widget.student.registrationDate;

    /*
     * قبل سنة التسجيل.
     */
    if (_selectedYear < registrationDate.year) {
      return 0;
    }

    /*
     * بعد السنة الحالية:
     * لا توجد شهور مستحقة.
     */
    if (_selectedYear > now.year) {
      return 0;
    }

    /*
     * سنوات سابقة:
     * كل شهور السنة مستحقة بعد التسجيل.
     */
    if (_selectedYear < now.year) {
      return 12;
    }

    /*
     * السنة الحالية:
     * حتى الشهر الحالي فقط.
     */
    return now.month;
  }

  bool _isMonthDue(
      int month,
      int year,
      ) {
    final firstMonth =
        _firstDueMonthForSelectedYear;

    final lastMonth =
        _lastDueMonthForSelectedYear;

    if (firstMonth > 12) {
      return false;
    }

    return year == _selectedYear &&
        month >= firstMonth &&
        month <= lastMonth;
  }

  bool _isFutureMonth(
      int month,
      int year,
      ) {
    final now = DateTime.now();

    /*
     * أي سنة مستقبلية.
     */
    if (year > now.year) {
      return true;
    }

    /*
     * سنة أقدم من الحالية:
     * الشهر ليس Future.
     */
    if (year < now.year) {
      return false;
    }

    /*
     * قبل تاريخ تسجيل الطالب.
     */
    final registrationDate =
        widget.student.registrationDate;

    if (year == registrationDate.year &&
        month < registrationDate.month) {
      return false;
    }

    /*
     * الشهر الحالي أو الماضي.
     */
    return month > now.month;
  }

  // ============================================================
  // YEAR HELPERS
  // ============================================================

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;

    final years = <int>{
      currentYear,
      currentYear - 1,
      currentYear + 1,
      widget.student.registrationDate.year,
    };

    for (final payment in _payments) {
      years.add(payment.year);
    }

    final result = years.toList();

    result.sort();

    return result;
  }

  // ============================================================
  // YEAR STATISTICS
  // ============================================================

  List<PaymentModel> get _selectedYearPayments {
    return _payments
        .where(
          (payment) =>
      payment.year == _selectedYear,
    )
        .toList();
  }

  int get _paidMonths {
    int count = 0;

    for (int month = 1; month <= 12; month++) {
      if (_isMonthDue(
        month,
        _selectedYear,
      )) {
        final payment = _getPaymentForMonth(
          month,
          _selectedYear,
        );

        if (payment != null && payment.isPaid) {
          count++;
        }
      }
    }

    return count;
  }

  int get _dueMonths {
    final firstMonth =
        _firstDueMonthForSelectedYear;

    final lastMonth =
        _lastDueMonthForSelectedYear;

    if (firstMonth > 12 ||
        lastMonth < firstMonth) {
      return 0;
    }

    return lastMonth - firstMonth + 1;
  }

  int get _unpaidMonths {
    int unpaid = 0;

    for (int month = 1; month <= 12; month++) {
      if (!_isMonthDue(
        month,
        _selectedYear,
      )) {
        continue;
      }

      final payment = _getPaymentForMonth(
        month,
        _selectedYear,
      );

      if (payment == null || !payment.isPaid) {
        unpaid++;
      }
    }

    return unpaid;
  }

  double get _totalPaid {
    return _selectedYearPayments
        .where((payment) => payment.isPaid)
        .fold(
      0,
          (total, payment) =>
      total + payment.amount,
    );
  }

  double get _remainingAmount {
    double total = 0;

    for (int month = 1; month <= 12; month++) {
      if (!_isMonthDue(
        month,
        _selectedYear,
      )) {
        continue;
      }

      final payment = _getPaymentForMonth(
        month,
        _selectedYear,
      );

      if (payment == null || !payment.isPaid) {
        total += _getAmount(
          month,
          _selectedYear,
        );
      }
    }

    return total;
  }

  // ============================================================
  // PAYMENT ACTIONS
  // ============================================================

  Future<void> _payMonth({
    required int month,
    required int year,
  }) async {
    if (!_isMonthDue(
      month,
      year,
    )) {
      _showMessage(
        _isFutureMonth(month, year)
            ? 'لا يمكن تسجيل دفع لشهر لم يأتِ بعد.'
            : 'هذا الشهر غير مستحق على الطالب.',
        isError: true,
      );

      return;
    }

    if (_level == null) {
      _showMessage(
        'لا يوجد مستوى مرتبط بحصة الطالب، تأكد من إعداد الحصة.',
        isError: true,
      );

      return;
    }

    final existingPayment =
    _getPaymentForMonth(
      month,
      year,
    );

    /*
     * لو فيه دفع قديم ومدفوع بالفعل:
     * نحافظ على المبلغ التاريخي.
     *
     * لو مفيش دفع أو السجل غير مدفوع:
     * نستخدم السعر الحالي للمستوى.
     */
    final amount =
    existingPayment != null &&
        existingPayment.isPaid
        ? existingPayment.amount
        : _level!.monthlyFee;

    final now = DateTime.now();

    final payment = PaymentModel(
      id: existingPayment?.id ??
          PaymentService.buildPaymentId(
            widget.student.id,
            year,
            month,
          ),
      studentId: widget.student.id,
      groupId: widget.student.groupId,
      levelId: _level!.id,
      levelName: _level!.name,
      amount: amount,
      month: month,
      year: year,
      isPaid: true,
      paidAt: now,
      createdAt:
      existingPayment?.createdAt ?? now,
    );

    try {
      if (existingPayment == null) {
        await PaymentService.addPayment(
          payment,
        );
      } else {
        await PaymentService.updatePayment(
          payment,
        );
      }

      await _loadData();

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم تسجيل دفع ${_getArabicMonth(month)} $year',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'تعذر تسجيل الدفع.',
        isError: true,
      );
    }
  }

  Future<void> _cancelMonthPayment({
    required int month,
    required int year,
  }) async {
    final payment =
    _getPaymentForMonth(
      month,
      year,
    );

    if (payment == null ||
        !payment.isPaid) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text(
            'إلغاء الدفع',
          ),
          content: Text(
            'هل أنت متأكد من إلغاء دفع '
                '${_getArabicMonth(month)} $year؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'رجوع',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                colors.error,
              ),
              child: const Text(
                'نعم، إلغاء الدفع',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await PaymentService.updatePaymentStatus(
        paymentId: payment.id,
        isPaid: false,
      );

      await _loadData();

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم إلغاء الدفع.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'تعذر إلغاء الدفع.',
        isError: true,
      );
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
        isError ? Colors.red : null,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _formatDate(
      DateTime date,
      ) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(
      int weekday,
      ) {
    const days = [
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    if (weekday >= 1 &&
        weekday <= 7) {
      return days[weekday];
    }

    return '';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل المصاريف',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable:
        Hive.box('payments')
            .listenable(),
        builder: (
            context,
            Box box,
            _,
            ) {
          return _isLoading
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : RefreshIndicator(
            onRefresh: _loadData,
            child:
            CustomScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child:
                  _buildStudentHeader(),
                ),

                SliverToBoxAdapter(
                  child:
                  _buildYearSelector(),
                ),

                SliverToBoxAdapter(
                  child:
                  _buildStatistics(),
                ),

                SliverToBoxAdapter(
                  child:
                  _buildCurrentMonth(),
                ),

                SliverToBoxAdapter(
                  child:
                  _buildHistoryTitle(),
                ),

                SliverPadding(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    0,
                    16,
                    30,
                  ),
                  sliver:
                  SliverList.builder(
                    itemCount: 12,
                    itemBuilder:
                        (context, index) {
                      final month =
                          index + 1;

                      return _buildMonthCard(
                        month: month,
                        year:
                        _selectedYear,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // STUDENT HEADER
  // ============================================================

  Widget _buildStudentHeader() {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        10,
      ),
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius:
          BorderRadius.circular(22),
          border: Border.all(
            color: colors.outline
                .withOpacity(.12),
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              child: Text(
                widget.student.name
                    .isNotEmpty
                    ? widget.student.name[0]
                    : '?',
                style:
                const TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              widget.student.name,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            if (_level != null)
              _headerInfo(
                Icons.school_outlined,
                _level!.name,
              ),

            if (_level != null)
              _headerInfo(
                Icons.payments_outlined,
                '${_level!.monthlyFee.toStringAsFixed(0)} '
                    'ج.م / شهر',
              ),

            if (_schedule != null)
              _headerInfo(
                Icons.schedule_outlined,
                '${_getDayName(_schedule!.weekday)} • '
                    '${_schedule!.startTime} - '
                    '${_schedule!.endTime}',
              ),

            const SizedBox(
              height: 6,
            ),

            _headerInfo(
              Icons.person_add_alt_1_outlined,
              'تاريخ التسجيل: '
                  '${_formatDate(widget.student.registrationDate)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerInfo(
      IconData icon,
      String text,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
      const EdgeInsets.only(
        top: 6,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 17,
            color: colors.primary,
          ),
          const SizedBox(
            width: 6,
          ),
          Flexible(
            child: Text(
              text,
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface
                    .withOpacity(.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YEAR SELECTOR
  // ============================================================

  Widget _buildYearSelector() {
    final colors =
        Theme.of(context).colorScheme;

    final years =
        _availableYears;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        6,
        16,
        8,
      ),
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        decoration:
        BoxDecoration(
          color: colors.surface,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: colors.outline
                .withOpacity(.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons
                  .calendar_today_rounded,
              color:
              colors.primary,
              size: 20,
            ),

            const SizedBox(
              width: 10,
            ),

            const Text(
              'السنة',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
              DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                underline:
                const SizedBox(),
                alignment:
                Alignment.centerRight,
                items: years.map(
                      (year) {
                    return DropdownMenuItem<
                        int>(
                      value: year,
                      child:
                      Text('$year'),
                    );
                  },
                ).toList(),
                onChanged:
                    (value) {
                  if (value ==
                      null) {
                    return;
                  }

                  setState(() {
                    _selectedYear =
                        value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'تم الدفع',
                  value:
                  '$_paidMonths',
                  icon: Icons
                      .check_circle_outline,
                  iconColor:
                  Colors.green,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _statCard(
                  title: 'غير مدفوع',
                  value:
                  '$_unpaidMonths',
                  icon: Icons
                      .warning_amber_rounded,
                  iconColor:
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  title:
                  'إجمالي المدفوع',
                  value:
                  '${_totalPaid.toStringAsFixed(0)} ج.م',
                  icon: Icons
                      .account_balance_wallet_outlined,
                  iconColor:
                  Colors.blue,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _statCard(
                  title: 'المتبقي',
                  value:
                  '${_remainingAmount.toStringAsFixed(0)} ج.م',
                  icon: Icons
                      .pending_actions_rounded,
                  iconColor:
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    final colors =
        Theme.of(context).colorScheme;

    final color =
        iconColor ?? colors.primary;

    return Container(
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: colors.outline
              .withOpacity(.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color:
              color.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors
                        .onSurface
                        .withOpacity(.6),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT MONTH
  // ============================================================

  Widget _buildCurrentMonth() {
    final now = DateTime.now();

    final colors =
        Theme.of(context).colorScheme;

    final isCurrentYear =
        _selectedYear == now.year;

    final currentMonthIsDue =
    _isMonthDue(
      now.month,
      now.year,
    );

    final payment =
    isCurrentYear &&
        currentMonthIsDue
        ? _getPaymentForMonth(
      now.month,
      now.year,
    )
        : null;

    final isPaid =
        payment != null &&
            payment.isPaid;

    final amount =
    isCurrentYear &&
        currentMonthIsDue
        ? _getAmount(
      now.month,
      now.year,
    )
        : 0;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16,
      ),
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient:
          LinearGradient(
            colors: [
              colors.primary
                  .withOpacity(.14),
              colors.primary
                  .withOpacity(.04),
            ],
          ),
          borderRadius:
          BorderRadius.circular(22),
          border: Border.all(
            color: colors.primary
                .withOpacity(.15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons
                      .calendar_month_outlined,
                  color:
                  colors.primary,
                ),

                const SizedBox(
                  width: 8,
                ),

                const Expanded(
                  child: Text(
                    'الشهر الحالي',
                    style:
                    TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '${_getArabicMonth(now.month)} '
                      '${now.year}',
                  style: TextStyle(
                    color:
                    colors.primary,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 15,
            ),

            if (!isCurrentYear)
              Text(
                'اختر السنة الحالية لعرض حالة الشهر الحالي.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors
                      .onSurface
                      .withOpacity(.6),
                ),
              )
            else if (!currentMonthIsDue)
              Column(
                children: [
                  Icon(
                    Icons
                        .event_available_outlined,
                    color:
                    colors.primary,
                    size: 30,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'الشهر الحالي لم يصبح مستحقًا بعد.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors
                          .onSurface
                          .withOpacity(.6),
                    ),
                  ),
                ],
              )
            else ...[
                Row(
                  children: [
                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'المصاريف',
                            style:
                            TextStyle(
                              fontSize:
                              12,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '${amount.toStringAsFixed(0)} ج.م',
                            style:
                            const TextStyle(
                              fontSize:
                              21,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _paymentStatus(
                      isPaid,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 15,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  child:
                  FilledButton.icon(
                    onPressed: () {
                      if (isPaid) {
                        _cancelMonthPayment(
                          month:
                          now.month,
                          year:
                          now.year,
                        );
                      } else {
                        _payMonth(
                          month:
                          now.month,
                          year:
                          now.year,
                        );
                      }
                    },
                    icon: Icon(
                      isPaid
                          ? Icons.undo
                          : Icons
                          .payments_outlined,
                    ),
                    label: Text(
                      isPaid
                          ? 'إلغاء الدفع'
                          : 'تسجيل دفع الشهر',
                    ),
                    style: FilledButton
                        .styleFrom(
                      backgroundColor:
                      isPaid
                          ? Colors.red
                          : null,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY TITLE
  // ============================================================

  Widget _buildHistoryTitle() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        10,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history,
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            'سجل المصاريف $_selectedYear',
            style:
            const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONTH CARD
  // ============================================================

  Widget _buildMonthCard({
    required int month,
    required int year,
  }) {
    final colors =
        Theme.of(context).colorScheme;

    final payment =
    _getPaymentForMonth(
      month,
      year,
    );

    final isPaid =
        payment != null &&
            payment.isPaid;

    final isDue =
    _isMonthDue(
      month,
      year,
    );

    final isFuture =
    _isFutureMonth(
      month,
      year,
    );

    final isBeforeRegistration =
        year ==
            widget.student
                .registrationDate
                .year &&
            month <
                widget.student
                    .registrationDate
                    .month;

    final amount =
    _getAmount(
      month,
      year,
    );

    final now =
    DateTime.now();

    final isCurrentMonth =
        month == now.month &&
            year == now.year;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentMonth
              ? colors.primary
              .withOpacity(.3)
              : colors.outline
              .withOpacity(.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                BoxDecoration(
                  color: isPaid
                      ? Colors.green
                      .withOpacity(.1)
                      : isBeforeRegistration
                      ? Colors.blueGrey
                      .withOpacity(
                    .08,
                  )
                      : isFuture
                      ? Colors.grey
                      .withOpacity(
                    .1,
                  )
                      : Colors.red
                      .withOpacity(
                    .08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle
                      : isBeforeRegistration
                      ? Icons
                      .person_off_outlined
                      : isFuture
                      ? Icons
                      .schedule_outlined
                      : Icons
                      .radio_button_unchecked,
                  color: isPaid
                      ? Colors.green
                      : isBeforeRegistration
                      ? Colors.blueGrey
                      : isFuture
                      ? Colors.grey
                      : Colors.red,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getArabicMonth(
                            month,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          width: 7,
                        ),

                        if (isCurrentMonth)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              7,
                              vertical: 3,
                            ),
                            decoration:
                            BoxDecoration(
                              color: colors
                                  .primary
                                  .withOpacity(
                                .1,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                            child: Text(
                              'الحالي',
                              style:
                              TextStyle(
                                fontSize:
                                10,
                                color: colors
                                    .primary,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      isBeforeRegistration
                          ? 'قبل تسجيل الطالب'
                          : isFuture
                          ? 'لم يحن موعده بعد'
                          : '${amount.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors
                            .onSurface
                            .withOpacity(
                          .6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _paymentStatus(
                isPaid,
                isFuture:
                isFuture ||
                    isBeforeRegistration,
                beforeRegistration:
                isBeforeRegistration,
              ),
            ],
          ),

          if (isPaid &&
              payment?.paidAt != null) ...[
            const SizedBox(
              height: 10,
            ),

            Align(
              alignment:
              Alignment.centerRight,
              child: Text(
                'تم الدفع: '
                    '${_formatDate(payment!.paidAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors
                      .onSurface
                      .withOpacity(
                    .55,
                  ),
                ),
              ),
            ),
          ],

          if (isDue) ...[
            const SizedBox(
              height: 10,
            ),

            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton.icon(
                onPressed: () {
                  if (isPaid) {
                    _cancelMonthPayment(
                      month: month,
                      year: year,
                    );
                  } else {
                    _payMonth(
                      month: month,
                      year: year,
                    );
                  }
                },
                icon: Icon(
                  isPaid
                      ? Icons.undo
                      : Icons
                      .payments_outlined,
                  size: 18,
                ),
                label: Text(
                  isPaid
                      ? 'إلغاء الدفع'
                      : 'تسجيل الدفع',
                ),
                style: isPaid
                    ? OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  Colors.red,
                )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT STATUS
  // ============================================================

  Widget _paymentStatus(
      bool isPaid, {
        bool isFuture = false,
        bool beforeRegistration = false,
      }) {
    final color = isPaid
        ? Colors.green
        : beforeRegistration
        ? Colors.blueGrey
        : isFuture
        ? Colors.grey
        : Colors.red;

    final text = isPaid
        ? 'تم الدفع'
        : beforeRegistration
        ? 'قبل التسجيل'
        : isFuture
        ? 'لم يحن'
        : 'غير مدفوع';

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
        color.withOpacity(.1),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            isPaid
                ? Icons.check_circle
                : beforeRegistration
                ? Icons
                .person_off_outlined
                : isFuture
                ? Icons.schedule
                : Icons
                .cancel_outlined,
            size: 14,
            color: color,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}