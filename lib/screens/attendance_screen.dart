import 'dart:async';

import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';
import '../services/attendance_service.dart';
import '../services/class_session_service.dart';
import '../services/group_service.dart';
import '../services/student_service.dart';
import '../widgets/attendance_tile.dart';
import '../widgets/section_header.dart';

class AttendanceScreen extends StatefulWidget {
  final ClassScheduleModel schedule;

  const AttendanceScreen({
    super.key,
    required this.schedule,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<StudentModel> _students = [];

  GroupModel? _group;

  final Map<String, bool> _attendance = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEndingClass = false;

  ClassStatus _classStatus = ClassStatus.notStarted;

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    _loadAttendance();

    _statusTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _refreshClassStatus(),
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

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

  // ============================================================
  // Class Status
  // ============================================================

  Future<void> _refreshClassStatus() async {
    if (!mounted) {
      return;
    }

    try {
      final status = await ClassSessionService.getStatus(
        widget.schedule,
      );

      if (!mounted) {
        return;
      }

      if (status != _classStatus) {
        setState(() {
          _classStatus = status;
        });
      }
    } catch (_) {}
  }

  // ============================================================
  // Load Attendance
  // ============================================================

  Future<void> _loadAttendance() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // ==========================================================
      // التأكد إن الحصة تخص اليوم الحالي
      // ==========================================================

      final isToday = ClassSessionService.isTodaySchedule(
        widget.schedule,
      );

      if (!isToday) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'هذه الحصة متاحة يوم ${_dayName(widget.schedule.weekday)} فقط.',
                textAlign: TextAlign.right,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });

        return;
      }

      final results = await Future.wait([
        GroupService.getGroupById(
          widget.schedule.groupId,
        ),
        StudentService.getStudentsBySchedule(
          widget.schedule.id,
        ),
        AttendanceService.getAttendanceForClass(
          widget.schedule.id,
          DateTime.now(),
        ),
        ClassSessionService.getStatus(
          widget.schedule,
        ),
      ]);

      final group = results[0] as GroupModel?;

      final students = results[1] as List<StudentModel>;

      final records = results[2] as List<AttendanceModel>;

      final status = results[3] as ClassStatus;

      _attendance.clear();

      // كل طالب يبدأ غائب.
      for (final student in students) {
        _attendance[student.id] = false;
      }

      // استرجاع الحالة المسجلة.
      for (final record in records) {
        if (_attendance.containsKey(record.studentId)) {
          _attendance[record.studentId] = record.isPresent;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _group = group;
        _students = students;
        _classStatus = status;
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
          content: Text('تعذر تحميل بيانات الحضور.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // End Class
  // ============================================================

  Future<void> _endClass() async {
    if (_isEndingClass ||
        _classStatus == ClassStatus.ended ||
        _classStatus == ClassStatus.notStarted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.stop_circle_outlined,
                  color: colors.error,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إنهاء الحصة؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'بعد إنهاء الحصة لن تتمكن من تعديل الحضور والغياب لهذه الحصة اليوم.',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: colors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'إنهاء الحصة',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isEndingClass = true;
    });

    try {
      await ClassSessionService.markEnded(
        widget.schedule,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _classStatus = ClassStatus.ended;
        _isEndingClass = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنهاء الحصة.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1400),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isEndingClass = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر إنهاء الحصة.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // Save Attendance
  // ============================================================

  Future<void> _saveAttendance() async {
    if (_isSaving) {
      return;
    }

    // ==========================================================
    // حماية من حفظ حضور حصة في يوم مختلف
    // ==========================================================

    final isToday = ClassSessionService.isTodaySchedule(
      widget.schedule,
    );

    if (!isToday) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن تسجيل حضور هذه الحصة اليوم. موعدها يوم ${_dayName(widget.schedule.weekday)}.',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ==========================================================
    // تحديث حالة الحصة قبل الحفظ
    // ==========================================================

    final currentStatus = await ClassSessionService.getStatus(
      widget.schedule,
    );

    if (!mounted) {
      return;
    }

    if (currentStatus == ClassStatus.ended) {
      setState(() {
        _classStatus = ClassStatus.ended;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'انتهت الحصة وتم إغلاق الحضور.',
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _classStatus = currentStatus;
      _isSaving = true;
    });

    try {
      final today = DateTime.now();

      for (final student in _students) {
        final isPresent = _attendance[student.id] ?? false;

        final existing =
        await AttendanceService.getAttendanceRecord(
          student.id,
          widget.schedule.id,
          today,
        );

        final record = AttendanceModel(
          id: existing?.id ??
              '${widget.schedule.id}_${student.id}_'
                  '${today.year}_${today.month}_${today.day}',
          studentId: student.id,
          scheduleId: widget.schedule.id,
          date: today,
          isPresent: isPresent,
        );

        await AttendanceService.saveAttendance(record);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الحضور والغياب بنجاح.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1400),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ الحضور والغياب.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // Attendance Helpers
  // ============================================================

  void _setAll(bool value) {
    if (_classStatus == ClassStatus.ended) {
      return;
    }

    if (!ClassSessionService.isTodaySchedule(widget.schedule)) {
      return;
    }

    setState(() {
      for (final student in _students) {
        _attendance[student.id] = value;
      }
    });
  }

  int get _presentCount {
    return _students
        .where((student) => _attendance[student.id] == true)
        .length;
  }

  int get _absentCount {
    return _students.length - _presentCount;
  }

  double get _attendancePercentage {
    if (_students.isEmpty) {
      return 0;
    }

    return (_presentCount / _students.length) * 100;
  }

  String _statusTitle() {
    switch (_classStatus) {
      case ClassStatus.notStarted:
        return 'الحصة لم تبدأ بعد';

      case ClassStatus.running:
        return 'الحصة جارية الآن';

      case ClassStatus.ended:
        return 'انتهت الحصة';
    }
  }

  String _statusSubtitle() {
    switch (_classStatus) {
      case ClassStatus.notStarted:
        return 'يمكنك تجهيز الحضور قبل بداية الحصة.';

      case ClassStatus.running:
        return 'يمكنك تسجيل الحضور والغياب ثم إنهاء الحصة.';

      case ClassStatus.ended:
        return 'تم إغلاق الحضور لهذه الحصة اليوم.';
    }
  }

  Color _statusColor(ColorScheme colors) {
    switch (_classStatus) {
      case ClassStatus.notStarted:
        return colors.primary;

      case ClassStatus.running:
        return Colors.green;

      case ClassStatus.ended:
        return colors.error;
    }
  }

  IconData _statusIcon() {
    switch (_classStatus) {
      case ClassStatus.notStarted:
        return Icons.schedule_rounded;

      case ClassStatus.running:
        return Icons.play_circle_fill_rounded;

      case ClassStatus.ended:
        return Icons.check_circle_rounded;
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'الحضور والغياب',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      )
          : Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: _loadAttendance,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  6,
                  20,
                  24,
                ),
                children: [
                  _buildHero(colors),

                  const SizedBox(height: 14),

                  _buildStatusCard(colors),

                  const SizedBox(height: 18),

                  _buildAttendanceOverview(colors),

                  const SizedBox(height: 20),

                  SectionHeader(
                    title: 'الطلاب',
                    subtitle:
                    '${_students.length} طالب • $_presentCount حاضر',
                    actionText:
                    _students.isEmpty ||
                        _classStatus == ClassStatus.ended
                        ? null
                        : 'الكل حاضر',
                    onAction:
                    _students.isEmpty ||
                        _classStatus == ClassStatus.ended
                        ? null
                        : () => _setAll(true),
                  ),

                  const SizedBox(height: 12),

                  if (_students.isEmpty)
                    _buildEmpty(colors)
                  else
                    ..._students.map((student) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 9,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(
                            milliseconds: 200,
                          ),
                          opacity:
                          _classStatus == ClassStatus.ended
                              ? 0.68
                              : 1,
                          child: IgnorePointer(
                            ignoring:
                            _classStatus == ClassStatus.ended,
                            child: AttendanceTile(
                              student: student,
                              isPresent:
                              _attendance[student.id] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _attendance[student.id] = value;
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          _buildBottomBar(colors),
        ],
      ),
    );
  }

  // ============================================================
  // Hero
  // ============================================================

  Widget _buildHero(ColorScheme colors) {
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
              0.55,
            )!,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.16),
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _group?.name ?? 'المجموعة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.schedule.lessonTitle.trim().isEmpty
                          ? 'الحصة'
                          : widget.schedule.lessonTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.15,
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

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 17,
                  color: Colors.white,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '${widget.schedule.startTime} → ${widget.schedule.endTime}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                // ==================================================
                // Grade أصبح تابع للحصة ClassScheduleModel
                // ==================================================

                if (widget.schedule.grade.trim().isNotEmpty)
                  Flexible(
                    child: Text(
                      widget.schedule.grade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
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
  // Status
  // ============================================================

  Widget _buildStatusCard(ColorScheme colors) {
    final statusColor = _statusColor(colors);

    final running = _classStatus == ClassStatus.running;

    final ended = _classStatus == ClassStatus.ended;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(),
              size: 22,
              color: statusColor,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _statusSubtitle(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.35,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          if (running)
            SizedBox(
              height: 39,
              child: FilledButton.icon(
                onPressed:
                _isEndingClass ? null : _endClass,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isEndingClass
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.stop_rounded,
                  size: 16,
                ),
                label: const Text(
                  'إنهاء',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else if (ended)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: colors.error,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'مغلقة',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colors.error,
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
  // Attendance Overview
  // ============================================================

  Widget _buildAttendanceOverview(ColorScheme colors) {
    final present = _presentCount;
    final absent = _absentCount;
    final total = _students.length;
    final percentage = _attendancePercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'ملخص الحضور',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: total == 0 ? 0 : present / total,
              backgroundColor:
              colors.primary.withValues(alpha: 0.08),
              valueColor:
              AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  colors,
                  title: 'الإجمالي',
                  value: '$total',
                  icon: Icons.groups_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewItem(
                  colors,
                  title: 'حاضر',
                  value: '$present',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewItem(
                  colors,
                  title: 'غائب',
                  value: '$absent',
                  icon: Icons.cancel_rounded,
                  color: colors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(
      ColorScheme colors, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(height: 5),
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

  // ============================================================
  // Empty
  // ============================================================

  Widget _buildEmpty(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              size: 28,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'لا يوجد طلاب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'لم يتم تسجيل أي طلاب لهذه الحصة حتى الآن.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Bottom Bar
  // ============================================================

  Widget _buildBottomBar(ColorScheme colors) {
    final ended = _classStatus == ClassStatus.ended;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        14,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: ended
              ? Container(
            key: const ValueKey('ended'),
            height: 50,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: colors.error.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 19,
                  color: colors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'تم إنهاء الحصة وإغلاق الحضور',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: colors.error,
                  ),
                ),
              ],
            ),
          )
              : SizedBox(
            key: const ValueKey('save'),
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed:
              _isSaving ? null : _saveAttendance,
              style: FilledButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.save_rounded,
                size: 19,
              ),
              label: Text(
                _isSaving
                    ? 'جارٍ حفظ البيانات...'
                    : 'حفظ الحضور والغياب',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}