import 'package:flutter/material.dart';

class AppDialog {
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = 'إلغاء',
    String confirmText = 'تأكيد',
    IconData? icon,
    bool isDestructive = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? colors.error.withValues(alpha: 0.10)
                          : colors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: isDestructive ? colors.error : colors.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(cancelText),
            ),
            FilledButton(
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    )
                  : null,
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
