import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../services/student_service.dart';
import '../widgets/loading_card.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import 'attendance_history_screen.dart';
import 'attendance_screen.dart';
import 'groups_screen.dart';
import 'schedule_screen.dart';
import 'students_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClassScheduleModel> _todaySchedules = [];
  List<GroupModel> _groups = [];
  List<StudentModel> _students = [];

  bool _isLoading = true;
  Timer? _statusTimer;
  late final Box _groupsBox;
  late final Box _studentsBox;
  late final Box _schedulesBox;

  int get _uniqueGroupCount {
    return _groups.map((group) => group.weekday).toSet().length;
  }

  int get _completedClassesToday {
    return _todaySchedules.where((schedule) {
      final start = _parseTime(schedule.startTime);
      final end = _parseTime(schedule.endTime);

      if (start == null || end == null) {
        return false;
      }

      final now = DateTime.now();

      final endDate = DateTime(
        now.year,
        now.month,
        now.day,
        end.hour,
        end.minute,
      );

      return now.isAtSameMomentAs(endDate) || now.isAfter(endDate);
    }).length;
  }

  int get _remainingClassesToday {
    final remaining = _todaySchedules.length - _completedClassesToday;

    return remaining < 0 ? 0 : remaining;
  }

  @override
  void initState() {
    super.initState();

    _groupsBox = Hive.box('groups');
    _studentsBox = Hive.box('students');
    _schedulesBox = Hive.box('schedules');

    _groupsBox.listenable().addListener(_onHiveChanged);
    _studentsBox.listenable().addListener(_onHiveChanged);
    _schedulesBox.listenable().addListener(_onHiveChanged);

    _loadDashboard();

    _statusTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (!mounted) {
          return;
        }

        setState(() {});
      },
    );
  }

  void _onHiveChanged() {
    if (!mounted) {
      return;
    }

    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      if (_todaySchedules.isEmpty && _groups.isEmpty && _students.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
      }

      final today = _hessatyWeekday(DateTime.now());

      final results = await Future.wait([
        ScheduleService.getSchedulesByDay(today),
        GroupService.getGroups(),
        StudentService.getStudents(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _todaySchedules = results[0] as List<ClassScheduleModel>;
        _groups = results[1] as List<GroupModel>;
        _students = results[2] as List<StudentModel>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحميل بيانات الرئيسية.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static int _hessatyWeekday(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 1;
      case DateTime.sunday:
        return 2;
      case DateTime.monday:
        return 3;
      case DateTime.tuesday:
        return 4;
      case DateTime.wednesday:
        return 5;
      case DateTime.thursday:
        return 6;
      case DateTime.friday:
        return 7;
      default:
        return 1;
    }
  }

  TimeOfDay? _parseTime(String value) {
    final cleaned = value.trim().toUpperCase();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM|ص|م)?$',
    ).firstMatch(cleaned);

    if (match == null) {
      return null;
    }

    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = match.group(3);

    if ((period == 'AM' || period == 'ص') && hour == 12) {
      hour = 0;
    }

    if ((period == 'PM' || period == 'م') && hour != 12) {
      hour += 12;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  GroupModel? _getGroup(String groupId) {
    for (final group in _groups) {
      if (group.id == groupId) {
        return group;
      }
    }

    return null;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'صباح الخير 👋';
    }

    if (hour < 17) {
      return 'أهلاً بيك 👋';
    }

    return 'مساء الخير 👋';
  }

  String _getTodayName() {
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    return days[_hessatyWeekday(DateTime.now()) - 1];
  }

  String _formatTodayDate() {
    final now = DateTime.now();

    return '${now.day} ${_monthName(now.month)} ${now.year}';
  }

  String _monthName(int month) {
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

    if (month < 1 || month > months.length) {
      return '';
    }

    return months[month - 1];
  }

  void _openSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

  void _openStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentsScreen()),
    );
  }

  void _openGroups() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupsScreen()),
    );
  }

  void _openAttendance(ClassScheduleModel schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendanceScreen(schedule: schedule)),
    );
  }

  void _openAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
    );
  }
  @override
  void dispose() {
    _statusTimer?.cancel();

    _groupsBox.listenable().removeListener(_onHiveChanged);
    _studentsBox.listenable().removeListener(_onHiveChanged);
    _schedulesBox.listenable().removeListener(_onHiveChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          backgroundColor: colors.surface,
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                sliver: SliverToBoxAdapter(
                  child: _buildContent(context, colors),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colors) {
    if (_isLoading) {
      return const Column(
        children: [LoadingCard(type: LoadingCardType.schedule, itemCount: 3)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(colors),
        const SizedBox(height: 16),
        _buildTodayHero(colors),
        const SizedBox(height: 18),
        _buildOverview(colors),
        const SizedBox(height: 28),
        _buildTodaySection(colors),
        const SizedBox(height: 28),
        _buildQuickAccess(colors),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                Color.lerp(colors.primary, colors.primaryContainer, 0.55)!,
              ],
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(Icons.school_rounded, size: 26, color: colors.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حصتي',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.30),
                ),
              ),

            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayHero(ColorScheme colors) {
    final hasClasses = _todaySchedules.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.primaryContainer, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTodayDate(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimary.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'خطة يوم ${_getTodayName()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colors.onPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      hasClasses
                          ? 'عندك ${_todaySchedules.length} ${_todaySchedules.length == 1 ? 'حصة' : 'حصص'} النهارده.'
                          : 'النهارده مفيش حصص مجدولة.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: colors.onPrimary.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.onPrimary.withValues(alpha: 0.10),
                  ),
                ),
                child: Icon(
                  hasClasses
                      ? Icons.event_available_rounded
                      : Icons.free_breakfast_rounded,
                  color: colors.onPrimary,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildHeroMetric(
                colors,
                icon: Icons.calendar_today_rounded,
                value: '${_todaySchedules.length}',
                label: 'الحصص',
              ),
              const SizedBox(width: 8),
              _buildHeroMetric(
                colors,
                icon: Icons.check_circle_outline_rounded,
                value: '$_completedClassesToday',
                label: 'انتهت',
              ),
              const SizedBox(width: 8),
              _buildHeroMetric(
                colors,
                icon: Icons.timelapse_rounded,
                value: '$_remainingClassesToday',
                label: 'متبقية',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(
    ColorScheme colors, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: colors.onPrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: colors.onPrimary.withValues(alpha: 0.90),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: colors.onPrimary.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نظرة سريعة',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.48,
          children: [
            StatCard(
              title: 'حصص اليوم',
              value: '${_todaySchedules.length}',
              subtitle: 'الحصص المجدولة',
              icon: Icons.calendar_today_rounded,
              onTap: _openSchedule,
            ),
            StatCard(
              title: 'الطلاب',
              value: '${_students.length}',
              subtitle: 'الطلاب المسجلون',
              icon: Icons.groups_rounded,
              onTap: _openStudents,
            ),
            StatCard(
              title: 'المجموعات',
              value: '$_uniqueGroupCount',
              subtitle: 'أيام الدراسة',
              icon: Icons.class_rounded,
              onTap: _openGroups,
            ),
            StatCard(
              title: 'الحالة',
              value: _todaySchedules.isEmpty ? 'راحة' : 'نشاط',
              subtitle: _todaySchedules.isEmpty ? 'يوم هادئ' : 'اليوم عندك حصص',
              icon: _todaySchedules.isEmpty
                  ? Icons.self_improvement_rounded
                  : Icons.bolt_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaySection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'حصص اليوم',
          subtitle:
              '${_getTodayName()} • ${_todaySchedules.length} ${_todaySchedules.length == 1 ? 'حصة' : 'حصص'}',
          actionText: 'عرض الكل',
          onAction: _openSchedule,
        ),
        const SizedBox(height: 12),
        if (_todaySchedules.isEmpty)
          _buildNoClasses(colors)
        else
          ..._todaySchedules.take(4).map((schedule) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ScheduleCard(
                schedule: schedule,
                group: _getGroup(schedule.groupId),
                isToday: true,
                onTap: () => _openAttendance(schedule),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildNoClasses(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 31,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'اليوم فاضي 🎉',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'مفيش حصص مجدولة النهارده. ممكن تستغل الوقت في مراجعة الجدول أو بيانات الطلاب.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.55,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: _openSchedule,
            icon: const Icon(Icons.calendar_month_rounded, size: 17),
            label: const Text('فتح الجدول'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'الوصول السريع',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'كل الأدوات المهمة في مكان واحد',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                colors,
                icon: Icons.calendar_month_rounded,
                title: 'الجدول',
                subtitle: 'الحصص الأسبوعية',
                onTap: _openSchedule,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction(
                colors,
                icon: Icons.groups_rounded,
                title: 'الطلاب',
                subtitle: '${_students.length} طالب مسجل',
                onTap: _openStudents,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                colors,
                icon: Icons.class_rounded,
                title: 'المجموعات',
                subtitle: '${_uniqueGroupCount} مجموعات',
                onTap: _openGroups,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction(
                colors,
                icon: Icons.fact_check_rounded,
                title: 'الحضور',
                subtitle: _todaySchedules.isEmpty
                    ? 'لا توجد حصة اليوم'
                    : 'ابدأ تسجيل الحضور',
                onTap: _todaySchedules.isEmpty
                    ? null
                    : () => _openAttendance(_todaySchedules.first),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildAttendanceHistoryAction(colors),
      ],
    );
  }

  Widget _buildAttendanceHistoryAction(ColorScheme colors) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: 1,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _openAttendanceHistory,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 92,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary.withValues(alpha: 0.14),
                        colors.primary.withValues(alpha: 0.07),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.fact_check_rounded,
                    size: 23,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل الحضور والغياب',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'راجع سجل حضور الطلاب ونسب الغياب',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 124,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 21, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
