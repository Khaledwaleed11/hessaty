import 'package:flutter/material.dart';

import '../models/student_model.dart';

class AttendanceTile extends StatelessWidget {
  final StudentModel student;
  final bool isPresent;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  const AttendanceTile({
    super.key,
    required this.student,
    required this.isPresent,
    required this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap ?? () => onChanged(!isPresent),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: isPresent
                ? colors.primary.withValues(alpha: 0.055)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPresent
                  ? colors.primary.withValues(alpha: 0.20)
                  : colors.outlineVariant.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isPresent
                    ? colors.primary.withValues(alpha: 0.12)
                    : colors.surfaceContainerHigh,
                child: Text(
                  _getInitials(student.name),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isPresent ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.grade,
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
              Column(
                children: [
                  Switch.adaptive(value: isPresent, onChanged: onChanged),
                  Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: isPresent
                          ? colors.primary
                          : colors.onSurfaceVariant,
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
