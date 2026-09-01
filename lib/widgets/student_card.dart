import 'package:flutter/material.dart';

import '../models/class_schedule_model.dart';
import '../models/student_model.dart';
import 'status_chip.dart';

enum StudentClassStatus { notStarted, running, ended }

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final ClassScheduleModel? schedule;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final double? attendanceRate;
  final StudentClassStatus? classStatus;

  const StudentCard({
    super.key,
    required this.student,
    this.schedule,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.attendanceRate,
    this.classStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getBorderColor(colors),
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
              _buildAvatar(colors),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContent(colors),
              ),
              const SizedBox(width: 6),
              _buildTrailing(colors),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(ColorScheme colors) {
    if (classStatus == StudentClassStatus.running) {
      return Colors.green.withValues(alpha: 0.30);
    }

    if (classStatus == StudentClassStatus.ended) {
      return colors.error.withValues(alpha: 0.22);
    }

    if (classStatus == StudentClassStatus.notStarted) {
      return colors.primary.withValues(alpha: 0.18);
    }

    return colors.outlineVariant.withValues(alpha: 0.30);
  }

  Widget _buildAvatar(ColorScheme colors) {
    final avatarColor = classStatus == StudentClassStatus.running
        ? Colors.green.withValues(alpha: 0.10)
        : classStatus == StudentClassStatus.ended
        ? colors.error.withValues(alpha: 0.08)
        : colors.primary.withValues(alpha: 0.10);

    final iconColor = classStatus == StudentClassStatus.running
        ? Colors.green
        : classStatus == StudentClassStatus.ended
        ? colors.error
        : colors.primary;

    return CircleAvatar(
      radius: 24,
      backgroundColor: avatarColor,
      child: Text(
        _getInitials(student.name),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    // الـ Schedule هو المصدر الأساسي للـ Grade.
    // student.grade موجود كـ fallback للبيانات القديمة.
    final grade = schedule?.grade.trim().isNotEmpty == true
        ? schedule!.grade
        : student.grade;

    return Column(
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

        if (grade.trim().isNotEmpty)
          Text(
            grade,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),

        if (schedule != null) ...[
          const SizedBox(height: 8),
          _buildScheduleInfo(colors),
        ],

        if (student.phone.isNotEmpty) ...[
          const SizedBox(height: 7),
          _buildMeta(
            colors,
            Icons.phone_outlined,
            student.phone,
          ),
        ],

        if (attendanceRate != null) ...[
          const SizedBox(height: 7),
          StatusChip(
            text: '${attendanceRate!.toStringAsFixed(0)}% حضور',
            type: attendanceRate! >= 75
                ? StatusChipType.success
                : attendanceRate! >= 50
                ? StatusChipType.warning
                : StatusChipType.error,
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleInfo(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _getScheduleBackground(colors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: _getScheduleColor(colors),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  _dayName(schedule!.weekday),
                  maxLines: 1,
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

          const SizedBox(height: 5),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 12,
                color: _getScheduleColor(colors),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${schedule!.startTime} → ${schedule!.endTime}',
                  maxLines: 1,
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

          const SizedBox(height: 5),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 12,
                color: _getScheduleColor(colors),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  schedule!.lessonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          if (classStatus != null) ...[
            const SizedBox(height: 6),
            _buildClassStatus(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildClassStatus(ColorScheme colors) {
    late final Color color;
    late final IconData icon;
    late final String text;

    switch (classStatus!) {
      case StudentClassStatus.notStarted:
        color = colors.primary;
        icon = Icons.schedule_rounded;
        text = 'لم تبدأ';
        break;

      case StudentClassStatus.running:
        color = Colors.green;
        icon = Icons.play_circle_fill_rounded;
        text = 'جارية الآن';
        break;

      case StudentClassStatus.ended:
        color = colors.error;
        icon = Icons.check_circle_rounded;
        text = 'انتهت';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScheduleBackground(ColorScheme colors) {
    if (classStatus == StudentClassStatus.running) {
      return Colors.green.withValues(alpha: 0.06);
    }

    if (classStatus == StudentClassStatus.ended) {
      return colors.error.withValues(alpha: 0.05);
    }

    return colors.primary.withValues(alpha: 0.05);
  }

  Color _getScheduleColor(ColorScheme colors) {
    if (classStatus == StudentClassStatus.running) {
      return Colors.green;
    }

    if (classStatus == StudentClassStatus.ended) {
      return colors.error;
    }

    return colors.primary;
  }

  Widget _buildMeta(
      ColorScheme colors,
      IconData icon,
      String text,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: colors.primary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(ColorScheme colors) {
    if (showActions) {
      return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'خيارات الطالب',
        icon: Icon(
          Icons.more_vert_rounded,
          color: colors.onSurfaceVariant,
        ),
        onSelected: (value) {
          if (value == 'edit') {
            onEdit?.call();
          } else if (value == 'delete') {
            onDelete?.call();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text('تعديل'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: colors.error,
                ),
                const SizedBox(width: 10),
                Text(
                  'حذف',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return Icon(
        Icons.arrow_forward_ios_rounded,
        size: 13,
        color: colors.onSurfaceVariant,
      );
    }

    return const SizedBox(width: 13);
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
}