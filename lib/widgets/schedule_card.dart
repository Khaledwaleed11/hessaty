import 'package:flutter/material.dart';

import '../models/class_schedule_model.dart';
import '../models/group_model.dart';
import '../services/class_session_service.dart';

class ScheduleCard extends StatelessWidget {
  final ClassScheduleModel schedule;
  final GroupModel? group;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isToday;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.group,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    this.isToday = false,
  });

  bool get _hasActions => showActions && (onEdit != null || onDelete != null);

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
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isToday
                  ? colors.primary.withValues(alpha: 0.28)
                  : colors.outlineVariant.withValues(alpha: 0.30),
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
              _buildTimeBox(colors),
              const SizedBox(width: 12),
              Expanded(child: _buildContent(colors)),
              const SizedBox(width: 8),
              _buildTrailing(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox(ColorScheme colors) {
    final backgroundColor = isToday
        ? colors.primary
        : colors.primary.withValues(alpha: 0.09);

    final foregroundColor = isToday ? colors.onPrimary : colors.primary;

    return Container(
      width: 72,
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_rounded, size: 17, color: foregroundColor),
          const SizedBox(height: 4),
          Text(
            schedule.startTime,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: foregroundColor,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 22,
            height: 1,
            color: foregroundColor.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 2),
          Text(
            schedule.endTime,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: foregroundColor.withValues(alpha: 0.80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isToday)
          FutureBuilder<ClassStatus>(
            future: ClassSessionService.getStatus(schedule),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 22);
              }

              return _buildStatusChip(colors, snapshot.data!);
            },
          ),
        if (isToday) const SizedBox(height: 7),
        Text(
          schedule.lessonTitle.trim().isEmpty
              ? 'درس بدون عنوان'
              : schedule.lessonTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        if (group != null) ...[
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 13, color: colors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  group!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (group!.grade.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group!.grade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ] else
          Row(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 13,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'لا توجد مجموعة محددة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatusChip(ColorScheme colors, ClassStatus status) {
    late final Color color;
    late final IconData icon;
    late final String text;

    switch (status) {
      case ClassStatus.notStarted:
        color = colors.primary;
        icon = Icons.schedule_rounded;
        text = 'لم تبدأ';
        break;

      case ClassStatus.running:
        color = Colors.green;
        icon = Icons.play_circle_fill_rounded;
        text = 'جارية الآن';
        break;

      case ClassStatus.ended:
        color = colors.error;
        icon = Icons.check_circle_rounded;
        text = 'انتهت';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, ColorScheme colors) {
    if (_hasActions) {
      return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'خيارات الحصة',
        icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (context) {
          return [
            if (onEdit != null)
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('تعديل'),
                  ],
                ),
              ),
            if (onDelete != null)
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
          ];
        },
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
}
