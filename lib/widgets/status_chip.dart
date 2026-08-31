import 'package:flutter/material.dart';

enum StatusChipType { success, warning, error, info, neutral }

class StatusChip extends StatelessWidget {
  final String text;
  final StatusChipType type;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.text,
    this.type = StatusChipType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;

    switch (type) {
      case StatusChipType.success:
        backgroundColor = Colors.green.withValues(alpha: 0.10);
        foregroundColor = Colors.green.shade700;
        break;

      case StatusChipType.warning:
        backgroundColor = Colors.orange.withValues(alpha: 0.10);
        foregroundColor = Colors.orange.shade800;
        break;

      case StatusChipType.error:
        backgroundColor = colors.error.withValues(alpha: 0.10);
        foregroundColor = colors.error;
        break;

      case StatusChipType.info:
        backgroundColor = colors.primary.withValues(alpha: 0.10);
        foregroundColor = colors.primary;
        break;

      case StatusChipType.neutral:
        backgroundColor = colors.surfaceContainerHighest;
        foregroundColor = colors.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
