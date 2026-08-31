import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../services/class_session_service.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../services/student_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_text_field.dart';
import '../widgets/section_header.dart';
import '../widgets/student_card.dart';
import 'groups_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<StudentModel> _students = [];
  List<GroupModel> _groups = [];
  List<ClassScheduleModel> _schedules = [];

  bool _isLoading = true;
  String _searchQuery = '';

  Timer? _statusTimer;

  late final Box _studentsBox;
  late final Box _groupsBox;
  late final Box _schedulesBox;

  @override
  void initState() {
    super.initState();

    _studentsBox = Hive.box('students');
    _groupsBox = Hive.box('groups');
    _schedulesBox = Hive.box('schedules');

    _studentsBox.listenable().addListener(_onHiveChanged);
    _groupsBox.listenable().addListener(_onHiveChanged);
    _schedulesBox.listenable().addListener(_onHiveChanged);

    _loadData();

    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  void _onHiveChanged() {
    if (!mounted) {
      return;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final firstLoad =
        _students.isEmpty && _groups.isEmpty && _schedules.isEmpty;

    if (firstLoad && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        StudentService.getStudents(),
        GroupService.getGroups(),
        ScheduleService.getSchedules(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _students = results[0] as List<StudentModel>;
        _groups = results[1] as List<GroupModel>;
        _schedules = results[2] as List<ClassScheduleModel>;
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
          content: Text('تعذر تحميل بيانات الطلاب.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<StudentModel> get _filteredStudents {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _students;
    }

    return _students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.phone.toLowerCase().contains(query) ||
          student.parentPhone.toLowerCase().contains(query) ||
          student.grade.toLowerCase().contains(query);
    }).toList();
  }

  int get _studentsWithScheduleCount {
    return _students.where((student) {
      return _getScheduleForStudent(student) != null;
    }).length;
  }

  int get _studentsWithoutScheduleCount {
    return _students.length - _studentsWithScheduleCount;
  }

  ClassScheduleModel? _getScheduleForStudent(StudentModel student) {
    for (final schedule in _schedules) {
      if (schedule.id == student.scheduleId) {
        return schedule;
      }
    }

    return null;
  }

  Future<StudentClassStatus?> _getStudentClassStatus(
    StudentModel student,
  ) async {
    final schedule = _getScheduleForStudent(student);

    if (schedule == null) {
      return null;
    }

    try {
      final status = await ClassSessionService.getStatus(schedule);

      switch (status) {
        case ClassStatus.notStarted:
          return StudentClassStatus.notStarted;

        case ClassStatus.running:
          return StudentClassStatus.running;

        case ClassStatus.ended:
          return StudentClassStatus.ended;
      }
    } catch (_) {
      return null;
    }
  }

  GroupModel? _getGroup(String groupId) {
    for (final group in _groups) {
      if (group.id == groupId) {
        return group;
      }
    }

    return null;
  }

  Future<void> _showStudentDialog({StudentModel? student}) async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف مجموعة أولًا قبل تسجيل الطلاب.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أضف الحصص والمواعيد أولًا من شاشة الجدول.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _StudentDialog(
          student: student,
          groups: _groups,
          schedules: _schedules,
        );
      },
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'حذف الطالب',
      message: 'هل تريد حذف ${student.name} نهائيًا من قائمة الطلاب؟',
      cancelText: 'إلغاء',
      confirmText: 'حذف',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await StudentService.removeStudent(student.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _students.removeWhere((item) => item.id == student.id);
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الطالب بنجاح.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حذف الطالب.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openGroups() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupsScreen()),
    );

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();

    _studentsBox.listenable().removeListener(_onHiveChanged);

    _groupsBox.listenable().removeListener(_onHiveChanged);

    _schedulesBox.listenable().removeListener(_onHiveChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: _buildAppBar(colors),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: colors.primary,
                    backgroundColor: colors.surface,
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                      children: [
                        _buildHeroHeader(colors),

                        const SizedBox(height: 16),

                        _buildSearchBox(colors),

                        const SizedBox(height: 18),

                        _buildOverview(colors),

                        const SizedBox(height: 24),

                        _buildStudentsSection(colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(colors),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colors) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surfaceContainerLowest,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الطلاب',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'إدارة الطلاب والحصص المرتبطة بهم',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              _buildAppBarAction(
                colors,
                icon: Icons.groups_rounded,
                onTap: _openGroups,
                tooltip: 'المجموعات',
              ),
              const SizedBox(width: 8),
              _buildAppBarAction(
                colors,
                icon: Icons.person_add_alt_1_rounded,
                onTap: () => _showStudentDialog(),
                tooltip: 'تسجيل طالب',
                highlighted: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAction(
    ColorScheme colors, {
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted
            ? colors.primary.withValues(alpha: 0.10)
            : colors.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: highlighted ? colors.primary : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.primaryContainer, 0.52)!,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_groups.length} مجموعات',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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
            'طلابك في مكان واحد',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _students.isEmpty
                ? 'ابدأ بتسجيل أول طالب وإسناده إلى إحدى حصصك.'
                : 'تابع الطلاب والحصص المرتبطة بهم بسهولة.',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  icon: Icons.people_alt_rounded,
                  value: '${_students.length}',
                  label: 'إجمالي الطلاب',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroMetric(
                  icon: Icons.event_available_rounded,
                  value: '$_studentsWithScheduleCount',
                  label: 'مرتبطون بحصة',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroMetric(
                  icon: Icons.schedule_rounded,
                  value: '$_studentsWithoutScheduleCount',
                  label: 'بدون حصة',
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: Colors.white),
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
            overflow: TextOverflow.ellipsis,
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

  Widget _buildSearchBox(ColorScheme colors) {
    final hasQuery = _searchQuery.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasQuery
              ? colors.primary.withValues(alpha: 0.35)
              : colors.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        textDirection: TextDirection.rtl,
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
          hintText: 'ابحث باسم الطالب أو الرقم...',
          hintTextDirection: TextDirection.rtl,
          hintStyle: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.search_rounded, color: colors.primary, size: 20),
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
                    color: colors.onSurfaceVariant,
                    size: 19,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              'اليوم',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
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
                icon: Icons.groups_rounded,
                title: 'المجموعات',
                value: '${_groups.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                colors,
                icon: Icons.calendar_month_rounded,
                title: 'الحصص',
                value: '${_schedules.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                colors,
                icon: Icons.person_rounded,
                title: 'الطلاب',
                value: '${_students.length}',
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection(ColorScheme colors) {
    final students = _filteredStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: _searchQuery.trim().isEmpty ? 'كل الطلاب' : 'نتائج البحث',
          subtitle: '${students.length} طالب',
          actionText: students.isEmpty ? null : 'تسجيل طالب',
          onAction: students.isEmpty ? null : () => _showStudentDialog(),
        ),

        const SizedBox(height: 12),

        if (students.isEmpty)
          _buildEmptyStudents(colors)
        else
          ...students.map((student) {
            final schedule = _getScheduleForStudent(student);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FutureBuilder<StudentClassStatus?>(
                future: _getStudentClassStatus(student),
                builder: (context, snapshot) {
                  return StudentCard(
                    student: student,
                    schedule: schedule,
                    classStatus: snapshot.data,
                    showActions: true,
                    onEdit: () => _showStudentDialog(student: student),
                    onDelete: () => _deleteStudent(student),
                  );
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyStudents(ColorScheme colors) {
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'لا توجد نتائج' : 'لا يوجد طلاب بعد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'جرّب البحث باسم مختلف أو استخدم رقم الهاتف.'
                : 'ابدأ الآن بتسجيل أول طالب في إحدى حصصك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 45,
              child: FilledButton.icon(
                onPressed: () => _showStudentDialog(),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  'تسجيل أول طالب',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colors) {
    return FloatingActionButton.extended(
      heroTag: 'students_add_fab',
      onPressed: () => _showStudentDialog(),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: 5,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: const Text(
        'تسجيل طالب',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StudentDialog extends StatefulWidget {
  final StudentModel? student;
  final List<GroupModel> groups;
  final List<ClassScheduleModel> schedules;

  const _StudentDialog({
    required this.student,
    required this.groups,
    required this.schedules,
  });

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<_StudentDialog> {
  late final TextEditingController _nameController;

  late final TextEditingController _phoneController;

  late final TextEditingController _parentPhoneController;

  late final TextEditingController _notesController;

  late int _selectedDay;
  late String _selectedScheduleId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final student = widget.student;

    _nameController = TextEditingController(text: student?.name ?? '');

    _phoneController = TextEditingController(text: student?.phone ?? '');

    _parentPhoneController = TextEditingController(
      text: student?.parentPhone ?? '',
    );

    _notesController = TextEditingController(text: student?.notes ?? '');

    final studentSchedule = _findScheduleForStudent();

    final initialSchedule = studentSchedule ?? _getFirstSchedule();

    _selectedScheduleId = initialSchedule.id;

    _selectedDay = initialSchedule.weekday;

    _syncSelectedSchedule();
  }

  ClassScheduleModel _getFirstSchedule() {
    final schedules = [...widget.schedules];

    schedules.sort((a, b) {
      if (a.weekday != b.weekday) {
        return a.weekday.compareTo(b.weekday);
      }

      return _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime));
    });

    return schedules.first;
  }

  ClassScheduleModel? _findScheduleForStudent() {
    final student = widget.student;

    if (student == null) {
      return null;
    }

    for (final schedule in widget.schedules) {
      if (schedule.id == student.scheduleId) {
        return schedule;
      }
    }

    for (final schedule in widget.schedules) {
      if (schedule.groupId == student.groupId) {
        return schedule;
      }
    }

    return null;
  }

  List<ClassScheduleModel> get _daySchedules {
    final schedules = widget.schedules
        .where((schedule) => schedule.weekday == _selectedDay)
        .toList();

    schedules.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );

    return schedules;
  }

  void _syncSelectedSchedule() {
    final schedules = _daySchedules;

    if (schedules.isEmpty) {
      _selectedScheduleId = '';
      return;
    }

    final exists = schedules.any(
      (schedule) => schedule.id == _selectedScheduleId,
    );

    if (!exists) {
      _selectedScheduleId = schedules.first.id;
    }
  }

  ClassScheduleModel? _getSelectedSchedule() {
    for (final schedule in widget.schedules) {
      if (schedule.id == _selectedScheduleId) {
        return schedule;
      }
    }

    return null;
  }

  GroupModel? _getSelectedGroup() {
    final schedule = _getSelectedSchedule();

    if (schedule == null) {
      return null;
    }

    return _getGroup(schedule.groupId);
  }

  GroupModel? _getGroup(String groupId) {
    for (final group in widget.groups) {
      if (group.id == groupId) {
        return group;
      }
    }

    return null;
  }

  String _dayName(int day) {
    const days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    if (day < 1 || day > days.length) {
      return '';
    }

    return days[day - 1];
  }

  int _timeToMinutes(String time) {
    final cleaned = time.trim().toUpperCase();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM|ص|م)?$',
    ).firstMatch(cleaned);

    if (match == null) {
      return 0;
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

    return (hour * 60) + minute;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedSchedule = _getSelectedSchedule();

    if (selectedSchedule == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر اليوم والحصة أولًا.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final selectedGroup = _getSelectedGroup();

    if (selectedGroup == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المجموعة المرتبطة بهذه الحصة غير موجودة.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existingStudent = widget.student;

      final student = StudentModel(
        id:
            existingStudent?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        grade: selectedGroup.grade,
        groupId: selectedGroup.id,
        notes: _notesController.text.trim(),
        registrationDate: existingStudent?.registrationDate ?? DateTime.now(),
        scheduleId: selectedSchedule.id,
      );

      await StudentService.addStudent(student);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ بيانات الطالب.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isEditing = widget.student != null;

    final daySchedules = _daySchedules;

    final selectedSchedule = _getSelectedSchedule();

    final selectedGroup = _getSelectedGroup();

    final selectedScheduleIsValid = daySchedules.any(
      (schedule) => schedule.id == _selectedScheduleId,
    );

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  Color.lerp(colors.primary, colors.primaryContainer, 0.55)!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
              size: 21,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'تعديل بيانات الطالب' : 'تسجيل طالب جديد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditing
                      ? 'حدّث بيانات الطالب وحصته'
                      : 'أضف الطالب إلى إحدى حصصك',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'الحصة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'حدد اليوم والحصة التي سينتمي إليها الطالب.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 8,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                initialValue: _selectedDay,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اليوم',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                items: List.generate(7, (index) {
                  final day = index + 1;

                  final hasClasses = widget.schedules.any(
                    (schedule) => schedule.weekday == day,
                  );

                  return DropdownMenuItem<int>(
                    value: day,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _dayName(day),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasClasses
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: hasClasses
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (!hasClasses)
                          Text(
                            'لا توجد حصص',
                            style: TextStyle(
                              fontSize: 8,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedDay = value;
                          _syncSelectedSchedule();
                        });
                      },
              ),

              const SizedBox(height: 14),

              if (daySchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.09),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 19,
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'لا توجد حصص في هذا اليوم. أضف حصة أولًا ثم ارجع لتسجيل الطالب.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.45,
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.045),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedScheduleIsValid
                        ? _selectedScheduleId
                        : daySchedules.first.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الحصة',
                      prefixIcon: Icon(Icons.access_time_rounded),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                    ),
                    items: daySchedules.map((schedule) {
                      final group = _getGroup(schedule.groupId);

                      final groupName = group?.name ?? 'مجموعة غير محددة';

                      return DropdownMenuItem<String>(
                        value: schedule.id,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '$groupName • ${schedule.startTime} → ${schedule.endTime}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _selectedScheduleId = value;
                            });
                          },
                  ),
                ),

              if (selectedSchedule != null && selectedGroup != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedGroup.name} • ${selectedSchedule.startTime} → ${selectedSchedule.endTime}',
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              Text(
                'بيانات الطالب',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 10),

              AppTextField(
                controller: _nameController,
                label: 'اسم الطالب',
                hintText: 'اكتب اسم الطالب',
                prefixIcon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اكتب اسم الطالب';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 13),

              AppTextField(
                controller: _phoneController,
                label: 'رقم هاتف الطالب',
                hintText: 'اختياري',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),

              const SizedBox(height: 13),

              AppTextField(
                controller: _parentPhoneController,
                label: 'رقم ولي الأمر',
                hintText: 'اختياري',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.contact_phone_outlined,
              ),

              const SizedBox(height: 13),

              AppTextField(
                controller: _notesController,
                label: 'ملاحظات',
                hintText: 'ملاحظات اختيارية',
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _isSaving || daySchedules.isEmpty ? null : _saveStudent,
          icon: _isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(
            _isSaving
                ? 'جارٍ الحفظ...'
                : isEditing
                ? 'حفظ التعديلات'
                : 'تسجيل الطالب',
          ),
        ),
      ],
    );
  }
}
