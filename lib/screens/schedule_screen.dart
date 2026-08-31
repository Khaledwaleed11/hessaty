import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import '../services/schedule_service.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/schedule_card.dart';
import '../widgets/section_header.dart';
import 'attendance_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ClassScheduleModel> _schedules = [];
  List<GroupModel> _groups = [];

  bool _isLoading = true;

  int _selectedDay = _hessatyWeekday(DateTime.now());

  late final Box _groupsBox;
  late final Box _schedulesBox;

  @override
  void initState() {
    super.initState();

    _groupsBox = Hive.box('groups');
    _schedulesBox = Hive.box('schedules');

    _groupsBox.listenable().addListener(_onHiveChanged);
    _schedulesBox.listenable().addListener(_onHiveChanged);

    _loadData();
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

  String _shortDayName(int day) {
    const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    if (day < 1 || day > days.length) {
      return '';
    }

    return days[day - 1];
  }

  void _onHiveChanged() {
    if (!mounted) {
      return;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final firstLoad = _schedules.isEmpty && _groups.isEmpty;

    if (firstLoad && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        ScheduleService.getSchedules(),
        GroupService.getGroups(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _schedules = results[0] as List<ClassScheduleModel>;
        _groups = results[1] as List<GroupModel>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _schedules = [];
        _groups = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحميل الجدول.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<ClassScheduleModel> get _selectedSchedules {
    final schedules = _schedules
        .where((schedule) => schedule.weekday == _selectedDay)
        .toList();

    schedules.sort(
      (a, b) =>
          _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)),
    );

    return schedules;
  }

  GroupModel? _getGroupForDay(int day) {
    for (final group in _groups) {
      if (group.weekday == day) {
        return group;
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

  Future<void> _showScheduleDialog({ClassScheduleModel? schedule}) async {
    if (_groups.isEmpty) {
      _showMessage('أضف مجموعة أولًا قبل إضافة الحصة.');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ScheduleDialog(
        schedule: schedule,
        groups: _groups,
        initialWeekday: schedule?.weekday ?? _selectedDay,
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deleteSchedule(ClassScheduleModel schedule) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'حذف الحصة',
      message: 'هل تريد حذف هذه الحصة من الجدول الأسبوعي؟',
      cancelText: 'إلغاء',
      confirmText: 'حذف',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ScheduleService.removeSchedule(schedule.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _schedules.removeWhere((item) => item.id == schedule.id);
      });

      _showMessage(
        'تم حذف الحصة بنجاح.',
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('تعذر حذف الحصة.');
    }
  }

  void _openAttendance(ClassScheduleModel schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttendanceScreen(schedule: schedule)),
    );
  }

  void _showMessage(String message, {IconData? icon}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 19),
                const SizedBox(width: 9),
              ],
              Expanded(child: Text(message, textAlign: TextAlign.right)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _groupsBox.listenable().removeListener(_onHiveChanged);
    _schedulesBox.listenable().removeListener(_onHiveChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final selectedGroup = _getGroupForDay(_selectedDay);
    final today = _hessatyWeekday(DateTime.now());
    final selectedSchedules = _selectedSchedules;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الجدول',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              selectedGroup == null
                  ? 'لا توجد مجموعة لهذا اليوم'
                  : selectedGroup.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (selectedGroup != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () => _showScheduleDialog(),
                tooltip: 'إضافة حصة',
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary.withValues(alpha: 0.09),
                ),
                icon: Icon(Icons.add_rounded, color: colors.primary),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _buildHeroHeader(
                        colors,
                        selectedGroup,
                        selectedSchedules,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                      child: _buildDaySelector(colors),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: SectionHeader(
                        title: _dayName(_selectedDay),
                        subtitle: selectedGroup == null
                            ? 'لا توجد مجموعة'
                            : '${selectedSchedules.length} ${selectedSchedules.length == 1 ? 'حصة' : 'حصص'}',
                        actionText: selectedGroup == null ? null : 'إضافة حصة',
                        onAction: selectedGroup == null
                            ? null
                            : () => _showScheduleDialog(),
                      ),
                    ),
                  ),
                  if (selectedGroup == null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                      sliver: SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.groups_outlined,
                          title: 'لا توجد مجموعة لهذا اليوم',
                          message:
                              'أضف مجموعة لهذا اليوم من شاشة المجموعات ثم يمكنك إنشاء الحصص الخاصة بها.',
                          buttonText: 'إضافة المجموعة',
                          buttonIcon: Icons.groups_rounded,
                          onButtonPressed: _openGroupsMessage,
                        ),
                      ),
                    )
                  else if (selectedSchedules.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                      sliver: SliverToBoxAdapter(
                        child: _buildEmptySchedule(colors),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final schedule = selectedSchedules[index];
                          final isToday = schedule.weekday == today;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ScheduleCard(
                              schedule: schedule,
                              group: selectedGroup,
                              isToday: isToday,
                              showActions: true,
                              onTap: isToday
                                  ? () => _openAttendance(schedule)
                                  : null,
                              onEdit: () =>
                                  _showScheduleDialog(schedule: schedule),
                              onDelete: () => _deleteSchedule(schedule),
                            ),
                          );
                        }, childCount: selectedSchedules.length),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: selectedGroup == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'schedule_add_fab',
              onPressed: () => _showScheduleDialog(),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              elevation: 5,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة حصة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
    );
  }

  Widget _buildHeroHeader(
    ColorScheme colors,
    GroupModel? selectedGroup,
    List<ClassScheduleModel> schedules,
  ) {
    final today = _hessatyWeekday(DateTime.now());
    final isToday = _selectedDay == today;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.primaryContainer, 0.62)!,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'جدول اليوم' : 'جدول اليوم المختار',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dayName(_selectedDay),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  title: 'المجموعة',
                  value: selectedGroup?.name ?? 'غير موجودة',
                  icon: Icons.groups_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMetric(
                  title: 'الحصص',
                  value: '${schedules.length}',
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(ColorScheme colors) {
    final today = _hessatyWeekday(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'أيام الأسبوع',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '7 أيام',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = index + 1;
              final selected = day == _selectedDay;
              final isToday = day == today;
              final hasGroup = _getGroupForDay(day) != null;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 72,
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.primary,
                              Color.lerp(
                                colors.primary,
                                colors.primaryContainer,
                                0.45,
                              )!,
                            ],
                          )
                        : null,
                    color: selected ? null : colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : isToday
                          ? colors.primary.withValues(alpha: 0.40)
                          : colors.outlineVariant.withValues(alpha: 0.28),
                      width: selected ? 1.3 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.18),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _shortDayName(day),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: selected
                                    ? colors.onPrimary
                                    : colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: selected ? colors.onPrimary : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: hasGroup ? 7 : 5,
                        height: hasGroup ? 7 : 5,
                        decoration: BoxDecoration(
                          color: hasGroup
                              ? selected
                                    ? colors.onPrimary
                                    : colors.primary
                              : selected
                              ? colors.onPrimary.withValues(alpha: 0.35)
                              : colors.onSurfaceVariant.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySchedule(ColorScheme colors) {
    final group = _getGroupForDay(_selectedDay);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_send_rounded,
              size: 31,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'لا توجد حصص لهذا اليوم',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${group?.name ?? 'المجموعة'} موجودة، لكن لا توجد حصص مضافة إليها حتى الآن.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () => _showScheduleDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'إضافة أول حصة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGroupsMessage() {
    _showMessage(
      'اذهب إلى شاشة المجموعات وأضف مجموعة لهذا اليوم أولًا.',
      icon: Icons.groups_outlined,
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  final ClassScheduleModel? schedule;
  final List<GroupModel> groups;
  final int initialWeekday;

  const _ScheduleDialog({
    required this.schedule,
    required this.groups,
    required this.initialWeekday,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final TextEditingController _timeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _titleController;

  late int _selectedWeekday;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final schedule = widget.schedule;

    _timeController = TextEditingController(text: schedule?.startTime ?? '');

    _endTimeController = TextEditingController(text: schedule?.endTime ?? '');

    _titleController = TextEditingController(text: schedule?.lessonTitle ?? '');

    _selectedWeekday = schedule?.weekday ?? widget.initialWeekday;

    if (_selectedWeekday < 1 || _selectedWeekday > 7) {
      _selectedWeekday = widget.initialWeekday;
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _endTimeController.dispose();
    _titleController.dispose();

    super.dispose();
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';

    return '$hour:$minute $period';
  }

  Future<void> _pickStartTime() async {
    final initialTime = _parseTime(_timeController.text) ?? TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'اختر بداية الحصة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      hourLabelText: 'ساعة',
      minuteLabelText: 'دقيقة',
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _timeController.text = _formatTime(pickedTime);
    });
  }

  Future<void> _pickEndTime() async {
    final startTime = _parseTime(_timeController.text);

    final defaultEndTime = startTime == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    final initialTime = _parseTime(_endTimeController.text) ?? defaultEndTime;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'اختر نهاية الحصة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
      hourLabelText: 'ساعة',
      minuteLabelText: 'دقيقة',
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _endTimeController.text = _formatTime(pickedTime);
    });
  }

  GroupModel? _getGroupForSelectedDay() {
    for (final group in widget.groups) {
      if (group.weekday == _selectedWeekday) {
        return group;
      }
    }

    return null;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startTime = _timeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final title = _titleController.text.trim();

    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start == null || end == null) {
      _showError('اختار وقت البداية والنهاية بشكل صحيح.');
      return;
    }

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes <= startMinutes) {
      _showError('وقت النهاية يجب أن يكون بعد وقت البداية.');
      return;
    }

    final group = _getGroupForSelectedDay();

    if (group == null) {
      _showError('لا توجد مجموعة ليوم ${_dayName(_selectedWeekday)}.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existing = widget.schedule;

      final schedule = ClassScheduleModel(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        groupId: group.id,
        weekday: group.weekday,
        startTime: startTime,
        endTime: endTime,
        lessonTitle: title,
      );

      await ScheduleService.addSchedule(schedule);

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

      _showError('تعذر حفظ الحصة.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.schedule != null;
    final selectedGroup = _getGroupForSelectedDay();

    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEditing ? Icons.edit_calendar_rounded : Icons.add_task_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'تعديل الحصة' : 'إضافة حصة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEditing
                      ? 'تعديل بيانات الموعد الحالي'
                      : 'أضف موعدًا جديدًا للمجموعة',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
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
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedWeekday,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اليوم',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                items: List.generate(7, (index) {
                  final day = index + 1;
                  final hasGroup = widget.groups.any(
                    (group) => group.weekday == day,
                  );

                  return DropdownMenuItem<int>(
                    value: day,
                    enabled: hasGroup,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dayName(day),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: hasGroup
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant.withValues(
                                      alpha: 0.45,
                                    ),
                            ),
                          ),
                        ),
                        if (!hasGroup)
                          Text(
                            'بدون مجموعة',
                            style: TextStyle(
                              fontSize: 8,
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.50,
                              ),
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
                          _selectedWeekday = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedGroup == null
                      ? colors.error.withValues(alpha: 0.06)
                      : colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedGroup == null
                        ? colors.error.withValues(alpha: 0.15)
                        : colors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selectedGroup == null
                            ? colors.error.withValues(alpha: 0.10)
                            : colors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        selectedGroup == null
                            ? Icons.error_outline_rounded
                            : Icons.groups_rounded,
                        size: 19,
                        color: selectedGroup == null
                            ? colors.error
                            : colors.primary,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedGroup?.name ?? 'لا توجد مجموعة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: selectedGroup == null
                                  ? colors.error
                                  : colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedGroup == null
                                ? 'أضف مجموعة لهذا اليوم أولًا'
                                : selectedGroup.grade,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _timeController,
                      label: 'البداية',
                      hintText: 'اختيار الوقت',
                      prefixIcon: Icons.play_circle_outline_rounded,
                      suffixIcon: Icon(
                        Icons.access_time_rounded,
                        color: colors.primary,
                      ),
                      readOnly: true,
                      onTap: _pickStartTime,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اختر البداية';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _endTimeController,
                      label: 'النهاية',
                      hintText: 'اختيار الوقت',
                      prefixIcon: Icons.stop_circle_outlined,
                      suffixIcon: Icon(
                        Icons.access_time_filled_rounded,
                        color: colors.primary,
                      ),
                      readOnly: true,
                      onTap: _pickEndTime,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اختر النهاية';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _titleController,
                label: 'عنوان الدرس',
                hintText: 'مثال: الجبر',
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.menu_book_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اكتب عنوان الدرس';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'وقت البداية والنهاية يتم اختيارهما من Time Picker.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
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
          onPressed: _isSaving || selectedGroup == null ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isEditing ? Icons.check_rounded : Icons.add_rounded,
                  size: 18,
                ),
          label: Text(
            _isSaving
                ? 'جارٍ الحفظ...'
                : isEditing
                ? 'حفظ التعديل'
                : 'إضافة الحصة',
          ),
        ),
      ],
    );
  }
}
