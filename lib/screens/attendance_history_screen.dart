import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../services/attendance_service.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../services/student_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

enum _AttendanceFilter { all, present, absent }

enum _DateFilter { all, today, thisWeek, thisMonth }

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceModel> _records = [];
  List<StudentModel> _students = [];
  List<GroupModel> _groups = [];
  List<ClassScheduleModel> _schedules = [];

  bool _isLoading = true;

  String _searchQuery = '';

  _AttendanceFilter _attendanceFilter = _AttendanceFilter.all;
  _DateFilter _dateFilter = _DateFilter.all;

  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        AttendanceService.getAttendance(),
        StudentService.getStudents(),
        GroupService.getGroups(),
        ScheduleService.getSchedules(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = results[0] as List<AttendanceModel>;
        _students = results[1] as List<StudentModel>;
        _groups = results[2] as List<GroupModel>;
        _schedules = results[3] as List<ClassScheduleModel>;
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
          content: Text('تعذر تحميل سجل الحضور والغياب.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  StudentModel? _getStudent(String studentId) {
    for (final student in _students) {
      if (student.id == studentId) {
        return student;
      }
    }

    return null;
  }

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

  List<AttendanceModel> _buildCompleteRecords() {
    final result = <AttendanceModel>[];
    final processed = <String>{};

    for (final record in _records) {
      final schedule = _getSchedule(record.scheduleId);

      if (schedule == null) {
        result.add(record);
        continue;
      }

      final sessionDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );

      final studentsForSchedule = _students.where((student) {
        final sameSchedule = student.scheduleId == schedule.id;

        final registeredBeforeSession = !student.registrationDate.isAfter(
          sessionDate,
        );

        return sameSchedule && registeredBeforeSession;
      }).toList();

      if (studentsForSchedule.isEmpty) {
        result.add(record);
        continue;
      }

      for (final student in studentsForSchedule) {
        final key =
            '${student.id}_${schedule.id}_${sessionDate.year}_${sessionDate.month}_${sessionDate.day}';

        if (processed.contains(key)) {
          continue;
        }

        processed.add(key);

        final existingRecord = _findRecord(
          student.id,
          schedule.id,
          sessionDate,
        );

        if (existingRecord != null) {
          result.add(existingRecord);
        } else {
          result.add(
            AttendanceModel(
              id: '${schedule.id}_${student.id}_${sessionDate.year}_${sessionDate.month}_${sessionDate.day}',
              studentId: student.id,
              scheduleId: schedule.id,
              date: sessionDate,
              isPresent: false,
            ),
          );
        }
      }
    }

    return result;
  }

  AttendanceModel? _findRecord(
    String studentId,
    String scheduleId,
    DateTime date,
  ) {
    for (final record in _records) {
      if (record.studentId == studentId &&
          record.scheduleId == scheduleId &&
          _isSameDay(record.date, date)) {
        return record;
      }
    }

    return null;
  }

  List<AttendanceModel> get _filteredRecords {
    final completeRecords = _buildCompleteRecords();

    final query = _searchQuery.trim().toLowerCase();

    final filtered = completeRecords.where((record) {
      final student = _getStudent(record.studentId);

      if (student == null) {
        return false;
      }

      if (query.isNotEmpty) {
        final matchesSearch =
            student.name.toLowerCase().contains(query) ||
            student.phone.toLowerCase().contains(query) ||
            student.parentPhone.toLowerCase().contains(query);

        if (!matchesSearch) {
          return false;
        }
      }

      if (_attendanceFilter == _AttendanceFilter.present && !record.isPresent) {
        return false;
      }

      if (_attendanceFilter == _AttendanceFilter.absent && record.isPresent) {
        return false;
      }

      if (_selectedGroupId != null &&
          _selectedGroupId!.isNotEmpty &&
          student.groupId != _selectedGroupId) {
        return false;
      }

      if (!_matchesDateFilter(record.date)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();

    switch (_dateFilter) {
      case _DateFilter.all:
        return true;

      case _DateFilter.today:
        return _isSameDay(date, now);

      case _DateFilter.thisWeek:
        final todayOnly = DateTime(now.year, now.month, now.day);

        final startOfWeek = todayOnly.subtract(
          Duration(days: todayOnly.weekday - 1),
        );

        final endOfWeek = startOfWeek.add(const Duration(days: 7));

        return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);

      case _DateFilter.thisMonth:
        return date.year == now.year && date.month == now.month;
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  int get _presentCount {
    return _filteredRecords.where((record) => record.isPresent).length;
  }

  int get _absentCount {
    return _filteredRecords.where((record) => !record.isPresent).length;
  }

  int get _totalCount {
    return _filteredRecords.length;
  }

  double get _attendanceRate {
    if (_totalCount == 0) {
      return 0;
    }

    return (_presentCount / _totalCount) * 100;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _attendanceFilter = _AttendanceFilter.all;
      _dateFilter = _DateFilter.all;
      _selectedGroupId = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'م' : 'ص';

    return '$hour:$minute $period';
  }

  String _attendanceFilterLabel(_AttendanceFilter filter) {
    switch (filter) {
      case _AttendanceFilter.all:
        return 'الكل';

      case _AttendanceFilter.present:
        return 'الحاضرون';

      case _AttendanceFilter.absent:
        return 'الغائبون';
    }
  }

  String _dateFilterLabel(_DateFilter filter) {
    switch (filter) {
      case _DateFilter.all:
        return 'كل الفترات';

      case _DateFilter.today:
        return 'اليوم';

      case _DateFilter.thisWeek:
        return 'هذا الأسبوع';

      case _DateFilter.thisMonth:
        return 'هذا الشهر';
    }
  }

  IconData _attendanceFilterIcon(_AttendanceFilter filter) {
    switch (filter) {
      case _AttendanceFilter.all:
        return Icons.grid_view_rounded;

      case _AttendanceFilter.present:
        return Icons.check_circle_outline_rounded;

      case _AttendanceFilter.absent:
        return Icons.cancel_outlined;
    }
  }

  IconData _dateFilterIcon(_DateFilter filter) {
    switch (filter) {
      case _DateFilter.all:
        return Icons.calendar_month_rounded;

      case _DateFilter.today:
        return Icons.today_rounded;

      case _DateFilter.thisWeek:
        return Icons.date_range_rounded;

      case _DateFilter.thisMonth:
        return Icons.calendar_view_month_rounded;
    }
  }

  Future<void> _showStudentHistory(StudentModel student) async {
    final records =
        _buildCompleteRecords()
            .where((record) => record.studentId == student.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final present = records.where((record) => record.isPresent).length;
    final absent = records.length - present;

    final rate = records.isEmpty ? 0.0 : (present / records.length) * 100;

    if (!mounted) {
      return;
    }

    final colors = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.10,
                          ),
                          child: Text(
                            _getInitials(student.name),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                student.grade,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildHistoryStat(
                            colors,
                            icon: Icons.library_books_rounded,
                            value: '${records.length}',
                            label: 'إجمالي الحصص',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHistoryStat(
                            colors,
                            icon: Icons.check_circle_rounded,
                            value: '$present',
                            label: 'حضور',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHistoryStat(
                            colors,
                            icon: Icons.cancel_rounded,
                            value: '$absent',
                            label: 'غياب',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildHistoryStat(
                            colors,
                            icon: Icons.percent_rounded,
                            value: '${rate.toStringAsFixed(0)}%',
                            label: 'النسبة',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SectionHeader(
                      title: 'سجل الطالب',
                      subtitle: '${records.length} سجل',
                    ),

                    const SizedBox(height: 10),

                    if (records.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'لا توجد سجلات حضور لهذا الطالب حتى الآن.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final record = records[index];

                            final schedule = _getSchedule(record.scheduleId);

                            return Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: record.isPresent
                                          ? Colors.green.withValues(alpha: 0.10)
                                          : colors.error.withValues(
                                              alpha: 0.10,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      record.isPresent
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: record.isPresent
                                          ? Colors.green
                                          : colors.error,
                                      size: 21,
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          schedule?.lessonTitle ??
                                              'حصة غير محددة',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: colors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          schedule == null
                                              ? _formatDate(record.date)
                                              : '${_formatDate(record.date)} • ${schedule.startTime}',
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

                                  StatusChip(
                                    text: record.isPresent ? 'حاضر' : 'غائب',
                                    type: record.isPresent
                                        ? StatusChipType.success
                                        : StatusChipType.error,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryStat(
    ColorScheme colors, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: colors.primary),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

  Widget _buildSummary(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.55)!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الحضور',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'إحصائيات السجل الحالي',
                      style: TextStyle(fontSize: 9, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              Text(
                '${_attendanceRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              _buildSummaryItem(title: 'السجلات', value: '$_totalCount'),
              const SizedBox(width: 8),
              _buildSummaryItem(title: 'حضور', value: '$_presentCount'),
              const SizedBox(width: 8),
              _buildSummaryItem(title: 'غياب', value: '$_absentCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(colors),

        const SizedBox(height: 14),

        _buildFilterLabel(
          colors,
          icon: Icons.tune_rounded,
          title: 'حالة الحضور',
          value: _attendanceFilterLabel(_attendanceFilter),
        ),

        const SizedBox(height: 9),

        _buildFilterChips(
          colors,
          children: _AttendanceFilter.values.map((filter) {
            return _buildFilterChip(
              colors,
              label: _attendanceFilterLabel(filter),
              icon: _attendanceFilterIcon(filter),
              selected: _attendanceFilter == filter,
              onTap: () {
                setState(() {
                  _attendanceFilter = filter;
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        _buildFilterLabel(
          colors,
          icon: Icons.date_range_rounded,
          title: 'الفترة الزمنية',
          value: _dateFilterLabel(_dateFilter),
        ),

        const SizedBox(height: 9),

        _buildFilterChips(
          colors,
          children: _DateFilter.values.map((filter) {
            return _buildFilterChip(
              colors,
              label: _dateFilterLabel(filter),
              icon: _dateFilterIcon(filter),
              selected: _dateFilter == filter,
              onTap: () {
                setState(() {
                  _dateFilter = filter;
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        _buildFilterLabel(
          colors,
          icon: Icons.groups_rounded,
          title: 'المجموعة',
          value: _selectedGroupId == null
              ? 'كل المجموعات'
              : (_getGroup(_selectedGroupId!)?.name ?? 'المجموعة'),
        ),

        const SizedBox(height: 9),

        _buildGroupSelector(colors),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? colors.primary.withValues(alpha: 0.45)
              : colors.outlineVariant.withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
        decoration: InputDecoration(
          hintText: 'ابحث باسم الطالب أو رقم الهاتف...',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: Container(
            margin: const EdgeInsets.all(9),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.search_rounded, size: 20, color: colors.primary),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterLabel(
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: colors.primary),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    ColorScheme colors, {
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ColorScheme colors, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: selected ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outlineVariant.withValues(alpha: 0.28),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? colors.onPrimary : colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: selected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSelector(ColorScheme colors) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => _showGroupPicker(),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _selectedGroupId != null
                  ? colors.primary.withValues(alpha: 0.38)
                  : colors.outlineVariant.withValues(alpha: 0.30),
            ),
            color: _selectedGroupId != null
                ? colors.primary.withValues(alpha: 0.035)
                : colors.surface,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: 19,
                  color: colors.primary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedGroupId == null
                          ? 'كل المجموعات'
                          : (_getGroup(_selectedGroupId!)?.name ??
                                'مجموعة غير محددة'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedGroupId == null
                          ? 'اعرض سجلات جميع المجموعات'
                          : (_getGroup(_selectedGroupId!)?.grade ??
                                'بيانات المجموعة'),
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

              if (_selectedGroupId != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'إلغاء اختيار المجموعة',
                  onPressed: () {
                    setState(() {
                      _selectedGroupId = null;
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),

              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGroupPicker() async {
    final colors = Theme.of(context).colorScheme;

    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختيار المجموعة',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'اختر مجموعة لعرض سجلاتها فقط.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 14),

                _buildGroupOption(
                  context,
                  colors,
                  title: 'كل المجموعات',
                  subtitle: 'عرض جميع السجلات',
                  icon: Icons.grid_view_rounded,
                  selected: _selectedGroupId == null,
                  onTap: () {
                    Navigator.pop(context, null);
                  },
                ),

                const SizedBox(height: 8),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final group = _groups[index];

                      return _buildGroupOption(
                        context,
                        colors,
                        title: group.name,
                        subtitle: group.grade,
                        icon: Icons.groups_rounded,
                        selected: _selectedGroupId == group.id,
                        onTap: () {
                          Navigator.pop(context, group.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (selected != null || _selectedGroupId != null) {
      setState(() {
        _selectedGroupId = selected;
      });
    }
  }

  Widget _buildGroupOption(
    BuildContext context,
    ColorScheme colors, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.08)
          : colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.28)
                  : colors.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary
                      : colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: selected ? colors.onPrimary : colors.primary,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
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

              const SizedBox(width: 8),

              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: colors.primary,
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    ColorScheme colors,
    AttendanceModel record,
  ) {
    final student = _getStudent(record.studentId);

    final schedule = _getSchedule(record.scheduleId);

    if (student == null) {
      return const SizedBox.shrink();
    }

    final group = _getGroup(student.groupId);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showStudentHistory(student),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: record.isPresent
                  ? Colors.green.withValues(alpha: 0.18)
                  : colors.error.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.025),
                blurRadius: 12,
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
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    _getInitials(student.name),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      schedule?.lessonTitle ?? 'حصة غير محددة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 9,
                      runSpacing: 4,
                      children: [
                        if (group != null)
                          _buildMeta(colors, Icons.groups_outlined, group.name),
                        _buildMeta(
                          colors,
                          Icons.calendar_today_outlined,
                          _formatDate(record.date),
                        ),
                        if (schedule != null)
                          _buildMeta(
                            colors,
                            Icons.access_time_rounded,
                            schedule.startTime,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(
                    text: record.isPresent ? 'حاضر' : 'غائب',
                    type: record.isPresent
                        ? StatusChipType.success
                        : StatusChipType.error,
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _formatTime(record.date),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 5),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(ColorScheme colors, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: colors.primary),
        const SizedBox(width: 3),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,

      appBar: AppBar(
        title: const Text(
          'سجل الحضور والغياب',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                children: [
                  _buildSummary(colors),

                  const SizedBox(height: 22),

                  SectionHeader(
                    title: 'البحث والفلاتر',
                    subtitle: _hasActiveFilters
                        ? 'تم تطبيق فلاتر على السجل الحالي'
                        : 'ابحث وفلتر السجلات بسهولة',
                    actionText: _hasActiveFilters ? 'مسح الكل' : null,
                    onAction: _hasActiveFilters ? _clearFilters : null,
                  ),

                  const SizedBox(height: 13),

                  _buildFilters(colors),

                  const SizedBox(height: 24),

                  SectionHeader(
                    title: 'السجل',
                    subtitle: '${records.length} سجل',
                  ),

                  const SizedBox(height: 12),

                  if (records.isEmpty)
                    EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: _records.isEmpty
                          ? 'لا يوجد سجل حضور'
                          : 'لا توجد نتائج',
                      message: _records.isEmpty
                          ? 'سيظهر سجل الحضور والغياب هنا بعد تسجيل أول حصة.'
                          : 'جرّب تغيير البحث أو الفلاتر الحالية.',
                    )
                  else
                    ...records.map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRecordCard(context, colors, record),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  bool get _hasActiveFilters {
    return _searchQuery.trim().isNotEmpty ||
        _attendanceFilter != _AttendanceFilter.all ||
        _dateFilter != _DateFilter.all ||
        _selectedGroupId != null;
  }
}
