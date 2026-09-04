import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../models/level_model.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';

import '../services/group_service.dart';
import '../services/level_service.dart';
import '../services/payment_service.dart';
import '../services/schedule_service.dart';
import '../services/student_service.dart';

import '../widgets/section_header.dart';
import 'student_payment_details_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<StudentModel> _students = [];
  List<GroupModel> _groups = [];
  List<ClassScheduleModel> _schedules = [];
  List<LevelModel> _levels = [];
  List<PaymentModel> _payments = [];

  bool _isLoading = true;
  String _searchQuery = '';

  String _selectedStudentId = '';
  String _selectedScheduleId = '';

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  late final Box _paymentsBox;
  late final Box _studentsBox;

  final List<String> _months = const [
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

  @override
  void initState() {
    super.initState();

    _paymentsBox = Hive.box('payments');
    _studentsBox = Hive.box('students');

    _paymentsBox.listenable().addListener(
      _onPaymentsChanged,
    );

    _studentsBox.listenable().addListener(
      _onStudentsChanged,
    );

    _loadData();
  }

  void _onStudentsChanged() {
    if (!mounted) {
      return;
    }

    _loadData();
  }

  void _onPaymentsChanged() {
    if (!mounted) {
      return;
    }

    _reloadPayments();
  }

  @override
  void dispose() {
    _paymentsBox.listenable().removeListener(
      _onPaymentsChanged,
    );

    _studentsBox.listenable().removeListener(
      _onStudentsChanged,
    );

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        StudentService.getStudents(),
        GroupService.getGroups(),
        ScheduleService.getSchedules(),
        LevelService.getLevels(),
        PaymentService.getPayments(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _students = results[0] as List<StudentModel>;
        _groups = results[1] as List<GroupModel>;
        _schedules = results[2] as List<ClassScheduleModel>;
        _levels = results[3] as List<LevelModel>;
        _payments = results[4] as List<PaymentModel>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'تعذر تحميل بيانات المصروفات.',
        isError: true,
      );
    }
  }

  Future<void> _reloadPayments() async {
    try {
      final payments = await PaymentService.getPayments();

      if (!mounted) {
        return;
      }

      setState(() {
        _payments = payments;
      });
    } catch (_) {}
  }

  // ============================================================
  // HELPERS
  // ============================================================

  GroupModel? _getGroup(String groupId) {
    for (final group in _groups) {
      if (group.id == groupId) {
        return group;
      }
    }

    return null;
  }

  ClassScheduleModel? _getSchedule(String scheduleId) {
    for (final schedule in _schedules) {
      if (schedule.id == scheduleId) {
        return schedule;
      }
    }

    return null;
  }

  LevelModel? _getLevel(String levelId) {
    for (final level in _levels) {
      if (level.id == levelId) {
        return level;
      }
    }

    return null;
  }

  PaymentModel? _getPaymentForStudent(
      String studentId,
      ) {
    for (final payment in _payments) {
      if (payment.studentId == studentId &&
          payment.month == _selectedMonth &&
          payment.year == _selectedYear) {
        return payment;
      }
    }

    return null;
  }

  double _getStudentMonthlyFee(
      StudentModel student,
      ) {
    final level = _getLevel(student.levelId);

    return level?.monthlyFee ?? 0;
  }

  double _getStudentAmount(
      StudentModel student,
      ) {
    final payment = _getPaymentForStudent(
      student.id,
    );

    // لو فيه سجل دفع، المبلغ المخزن هو المرجع.
    if (payment != null) {
      return payment.amount;
    }

    // لو مفيش دفع، نجيب السعر الحالي للمستوى.
    return _getStudentMonthlyFee(student);
  }

  bool _isMonthBeforeRegistration(
      StudentModel student,
      ) {
    final registration = student.registrationDate;

    if (_selectedYear < registration.year) {
      return true;
    }

    if (_selectedYear == registration.year &&
        _selectedMonth < registration.month) {
      return true;
    }

    return false;
  }

  bool _isFutureMonth() {
    final now = DateTime.now();

    if (_selectedYear > now.year) {
      return true;
    }

    if (_selectedYear == now.year &&
        _selectedMonth > now.month) {
      return true;
    }

    return false;
  }

  bool _isMonthDue(
      StudentModel student,
      ) {
    if (_isMonthBeforeRegistration(student)) {
      return false;
    }

    if (_isFutureMonth()) {
      return false;
    }

    return true;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<StudentModel> get _filteredStudents {
    final query = _searchQuery.trim().toLowerCase();

    return _students.where((student) {
      final matchesSearch = query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.phone.toLowerCase().contains(query) ||
          student.parentPhone.toLowerCase().contains(query);

      final matchesStudent =
          _selectedStudentId.isEmpty ||
              student.id == _selectedStudentId;

      final matchesSchedule =
          _selectedScheduleId.isEmpty ||
              student.scheduleId == _selectedScheduleId;

      return matchesSearch &&
          matchesStudent &&
          matchesSchedule;
    }).toList();
  }

  // ============================================================
  // STATS
  // ============================================================

  int get _totalStudents {
    return _filteredStudents.length;
  }

  int get _paidStudents {
    return _filteredStudents.where((student) {
      if (!_isMonthDue(student)) {
        return false;
      }

      final payment = _getPaymentForStudent(
        student.id,
      );

      return payment != null && payment.isPaid;
    }).length;
  }

  int get _unpaidStudents {
    return _filteredStudents.where((student) {
      if (!_isMonthDue(student)) {
        return false;
      }

      final payment = _getPaymentForStudent(
        student.id,
      );

      return payment == null || !payment.isPaid;
    }).length;
  }

  double get _totalPaidAmount {
    double total = 0;

    for (final student in _filteredStudents) {
      if (!_isMonthDue(student)) {
        continue;
      }

      final payment = _getPaymentForStudent(
        student.id,
      );

      if (payment != null && payment.isPaid) {
        total += payment.amount;
      }
    }

    return total;
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Future<void> _payStudent(
      StudentModel student,
      ) async {
    if (!_isMonthDue(student)) {
      _showMessage(
        _isMonthBeforeRegistration(student)
            ? 'هذا الشهر يسبق تاريخ تسجيل الطالب.'
            : 'لا يمكن تسجيل دفع لشهر مستقبلي.',
        isError: true,
      );

      return;
    }

    final existingPayment =
    _getPaymentForStudent(student.id);

    final level = _getLevel(student.levelId);

    if (level == null) {
      _showMessage(
        'المستوى الخاص بالطالب غير موجود.',
        isError: true,
      );

      return;
    }

    final paymentId =
    PaymentService.buildPaymentId(
      student.id,
      _selectedYear,
      _selectedMonth,
    );

    final payment = PaymentModel(
      id: paymentId,
      studentId: student.id,
      groupId: student.groupId,
      levelId: student.levelId,
      levelName: level.name,

      // لو كان فيه مبلغ محفوظ قبل كده نحتفظ بيه.
      // غير كده نستخدم سعر المستوى الحالي.
      amount: existingPayment != null &&
          existingPayment.isPaid
          ? existingPayment.amount
          : level.monthlyFee,

      month: _selectedMonth,
      year: _selectedYear,
      isPaid: true,
      paidAt: DateTime.now(),
      createdAt:
      existingPayment?.createdAt ??
          DateTime.now(),
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

      await _reloadPayments();

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم تسجيل دفع ${student.name} بنجاح.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'تعذر تسجيل عملية الدفع.',
        isError: true,
      );
    }
  }

  Future<void> _cancelPayment(
      StudentModel student,
      ) async {
    final payment = _getPaymentForStudent(
      student.id,
    );

    if (payment == null) {
      return;
    }

    try {
      await PaymentService.updatePaymentStatus(
        paymentId: payment.id,
        isPaid: false,
      );

      await _reloadPayments();

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم إلغاء تسجيل الدفع.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'تعذر إلغاء عملية الدفع.',
        isError: true,
      );
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openStudentDetails(
      StudentModel student,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentPaymentDetailsScreen(
              student: student,
            ),
      ),
    );

    await _reloadPayments();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        isError ? Colors.red : null,
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
      colors.surfaceContainerLowest,
      appBar: _buildAppBar(colors),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        color: colors.primary,
        backgroundColor: colors.surface,
        onRefresh: _loadData,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          children: [
            _buildHeroHeader(colors),
            const SizedBox(height: 16),
            _buildSearchBox(colors),
            const SizedBox(height: 18),
            _buildFilters(colors),
            const SizedBox(height: 18),
            _buildMonthSelector(colors),
            const SizedBox(height: 24),
            _buildOverview(colors),
            const SizedBox(height: 24),
            _buildPaymentsSection(colors),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
      ColorScheme colors,
      ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor:
      colors.surfaceContainerLowest,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'المصروفات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'متابعة مصروفات الطلاب والمدفوعات الشهرية',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroHeader(
      ColorScheme colors,
      ) {
    final total = _totalStudents;
    final paid = _paidStudents;
    final unpaid = _unpaidStudents;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.lerp(
              colors.primary,
              colors.primaryContainer,
              0.52,
            )!,
          ],
        ),
        borderRadius:
        BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(
              alpha: 0.18,
            ),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_months[_selectedMonth - 1]} $_selectedYear',
                      style:
                      const TextStyle(
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'مصروفات طلابك',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'تابع حالة الدفع والمبالغ المستحقة لكل طالب بسهولة.',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: Colors.white.withValues(
                alpha: 0.76,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  icon: Icons.people_alt_rounded,
                  value: '$total',
                  label: 'الطلاب',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroMetric(
                  icon: Icons.check_circle_rounded,
                  value: '$paid',
                  label: 'تم الدفع',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroMetric(
                  icon: Icons.pending_rounded,
                  value: '$unpaid',
                  label: 'لم يتم الدفع',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.11,
        ),
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.white,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBox(
      ColorScheme colors,
      ) {
    final hasQuery =
        _searchQuery.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: hasQuery
              ? colors.primary.withValues(
            alpha: 0.35,
          )
              : colors.outlineVariant
              .withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(
              alpha: 0.025,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        textDirection:
        TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        decoration: InputDecoration(
          hintText:
          'ابحث باسم الطالب أو الرقم...',
          hintTextDirection:
          TextDirection.rtl,
          hintStyle: TextStyle(
            fontSize: 11,
            color:
            colors.onSurfaceVariant,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
              colors.primary.withValues(
                alpha: 0.09,
              ),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.search_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          suffixIcon: hasQuery
              ? IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
            icon: Icon(
              Icons.close_rounded,
              color:
              colors.onSurfaceVariant,
              size: 19,
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters(
      ColorScheme colors,
      ) {
    return Column(
      children: [
        _buildStudentFilter(colors),
        const SizedBox(height: 10),
        _buildScheduleFilter(colors),
      ],
    );
  }

  Widget _buildStudentFilter(
      ColorScheme colors,
      ) {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedStudentId.isEmpty
          ? null
          : _selectedStudentId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'الطالب',
        prefixIcon: const Icon(
          Icons.person_rounded,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.outlineVariant
                .withValues(alpha: 0.25),
          ),
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('كل الطلاب'),
        ),
        ..._students.map(
              (student) =>
              DropdownMenuItem<String>(
                value: student.id,
                child: Text(
                  student.name,
                  overflow:
                  TextOverflow.ellipsis,
                ),
              ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStudentId =
              value ?? '';
        });
      },
    );
  }

  Widget _buildScheduleFilter(
      ColorScheme colors,
      ) {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedScheduleId.isEmpty
          ? null
          : _selectedScheduleId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'الحصة',
        prefixIcon: const Icon(
          Icons.schedule_rounded,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.outlineVariant
                .withValues(alpha: 0.25),
          ),
        ),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text('كل الحصص'),
        ),
        ..._schedules.map(
              (schedule) {
            final group =
            _getGroup(schedule.groupId);

            final text = group == null
                ? schedule.lessonTitle
                : '${group.name} • ${schedule.lessonTitle}';

            return DropdownMenuItem<String>(
              value: schedule.id,
              child: Text(
                text,
                overflow:
                TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedScheduleId =
              value ?? '';
        });
      },
    );
  }

  // ============================================================
  // MONTH
  // ============================================================

  Widget _buildMonthSelector(
      ColorScheme colors,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
              colors.primary.withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                Text(
                  'الشهر المحدد',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  underline:
                  const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w900,
                    color: colors.onSurface,
                  ),
                  items: List.generate(
                    12,
                        (index) {
                      final month =
                          index + 1;

                      return DropdownMenuItem<
                          int>(
                        value: month,
                        child: Text(
                          '${_months[index]} $_selectedYear',
                        ),
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedMonth =
                          value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OVERVIEW
  // ============================================================

  Widget _buildOverview(
      ColorScheme colors,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'نظرة سريعة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ),
            Text(
              '${_months[_selectedMonth - 1]} $_selectedYear',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color:
                colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                colors,
                icon:
                Icons.people_alt_rounded,
                title: 'الطلاب',
                value:
                '$_totalStudents',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                colors,
                icon:
                Icons.check_circle_rounded,
                title: 'المدفوع',
                value:
                '$_paidStudents',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                colors,
                icon: Icons.payments_rounded,
                title: 'الإجمالي',
                value:
                '${_formatAmount(_totalPaidAmount)} ج.م',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat(
      ColorScheme colors, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color:
              colors.primary.withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color:
              colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENTS SECTION
  // ============================================================

  Widget _buildPaymentsSection(
      ColorScheme colors,
      ) {
    final students = _filteredStudents;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: _searchQuery.trim().isEmpty
              ? 'كل المصروفات'
              : 'نتائج البحث',
          subtitle:
          '${students.length} طالب',
        ),
        const SizedBox(height: 12),
        if (students.isEmpty)
          _buildEmptyPayments(colors)
        else
          ...students.map(
                (student) {
              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _buildPaymentCard(
                  colors,
                  student,
                ),
              );
            },
          ),
      ],
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard(
      ColorScheme colors,
      StudentModel student,
      ) {
    final payment =
    _getPaymentForStudent(student.id);

    final isPaid =
        payment != null && payment.isPaid;

    final level =
    _getLevel(student.levelId);

    final schedule =
    _getSchedule(student.scheduleId);

    final group =
    _getGroup(student.groupId);

    final amount =
    _getStudentAmount(student);

    final beforeRegistration =
    _isMonthBeforeRegistration(student);

    final futureMonth = _isFutureMonth();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openStudentDetails(student);
        },
        borderRadius:
        BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: beforeRegistration ||
                  futureMonth
                  ? colors.outlineVariant
                  .withValues(
                alpha: 0.25,
              )
                  : isPaid
                  ? Colors.green
                  .withValues(
                alpha: 0.30,
              )
                  : colors.outlineVariant
                  .withValues(
                alpha: 0.35,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow
                    .withValues(
                  alpha: 0.025,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // =========================
              // Header
              // =========================

              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                    colors.primary
                        .withValues(
                      alpha: 0.10,
                    ),
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name
                          .characters
                          .first
                          : '?',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w900,
                        fontSize: 18,
                        color:
                        colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .end,
                      children: [
                        Text(
                          student.name,
                          textAlign:
                          TextAlign.right,
                          style:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          level == null
                              ? 'المستوى غير محدد'
                              : level.name,
                          textAlign:
                          TextAlign.right,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                            FontWeight.w600,
                            color: colors
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatus(
                    colors,
                    isPaid: isPaid,
                    beforeRegistration:
                    beforeRegistration,
                    futureMonth:
                    futureMonth,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Divider(
                height: 1,
                color: colors
                    .outlineVariant
                    .withValues(
                  alpha: 0.35,
                ),
              ),

              const SizedBox(height: 12),

              // =========================
              // Info
              // =========================

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      colors,
                      icon:
                      Icons.groups_rounded,
                      title: 'المجموعة',
                      value:
                      group?.name ??
                          'غير محددة',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      colors,
                      icon:
                      Icons.schedule_rounded,
                      title: 'الحصة',
                      value:
                      schedule == null
                          ? 'غير محددة'
                          : '${schedule.startTime} - ${schedule.endTime}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      colors,
                      icon:
                      Icons.payments_rounded,
                      title: 'المبلغ',
                      value:
                      '${_formatAmount(amount)} ج.م',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // =========================
              // Buttons
              // =========================

              Row(
                children: [
                  Expanded(
                    child:
                    OutlinedButton.icon(
                      onPressed: () {
                        _openStudentDetails(
                          student,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .visibility_rounded,
                        size: 17,
                      ),
                      label:
                      const Text(
                        'التفاصيل',
                        style:
                        TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: beforeRegistration ||
                        futureMonth
                        ? OutlinedButton.icon(
                      onPressed: null,
                      icon:
                      Icon(
                        beforeRegistration
                            ? Icons
                            .history_toggle_off_rounded
                            : Icons
                            .event_rounded,
                        size: 17,
                      ),
                      label: Text(
                        beforeRegistration
                            ? 'غير مستحق'
                            : 'مستقبلي',
                        style:
                        const TextStyle(
                          fontSize:
                          11,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    )
                        : isPaid
                        ? OutlinedButton.icon(
                      onPressed: () {
                        _cancelPayment(
                          student,
                        );
                      },
                      icon:
                      const Icon(
                        Icons
                            .undo_rounded,
                        size: 17,
                      ),
                      label:
                      const Text(
                        'إلغاء الدفع',
                        style:
                        TextStyle(
                          fontSize:
                          11,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    )
                        : FilledButton.icon(
                      onPressed: () {
                        _payStudent(
                          student,
                        );
                      },
                      icon:
                      const Icon(
                        Icons
                            .check_rounded,
                        size: 17,
                      ),
                      label:
                      const Text(
                        'تم الدفع',
                        style:
                        TextStyle(
                          fontSize:
                          11,
                          fontWeight:
                          FontWeight
                              .w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus(
      ColorScheme colors, {
        required bool isPaid,
        required bool beforeRegistration,
        required bool futureMonth,
      }) {
    if (beforeRegistration) {
      return _statusContainer(
        color: colors.onSurfaceVariant,
        icon: Icons.remove_circle_outline,
        text: 'غير مستحق',
      );
    }

    if (futureMonth) {
      return _statusContainer(
        color: colors.primary,
        icon: Icons.event_rounded,
        text: 'مستقبلي',
      );
    }

    return _statusContainer(
      color:
      isPaid ? Colors.green : Colors.orange,
      icon: isPaid
          ? Icons.check_circle_rounded
          : Icons.access_time_rounded,
      text:
      isPaid ? 'تم الدفع' : 'لم يتم الدفع',
    );
  }

  Widget _statusContainer({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _buildInfoItem(
      ColorScheme colors, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
            colors.primary.withValues(
              alpha: 0.08,
            ),
            borderRadius:
            BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 17,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color:
            colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyPayments(
      ColorScheme colors,
      ) {
    final hasFilters =
        _searchQuery.trim().isNotEmpty ||
            _selectedStudentId.isNotEmpty ||
            _selectedScheduleId.isNotEmpty;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color:
              colors.primary.withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.payments_outlined,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasFilters
                ? 'لا توجد نتائج'
                : 'لا يوجد طلاب بعد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'جرّب تغيير البحث أو الفلاتر الحالية.'
                : 'سجّل الطلاب أولًا حتى تظهر مصروفاتهم هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color:
              colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}