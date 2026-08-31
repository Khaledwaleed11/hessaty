import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final IconData buttonIcon;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.buttonIcon = Icons.add_rounded,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: colors.primary),
            ),

            const SizedBox(height: 20),

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

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Text(
                message,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),

            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: Icon(buttonIcon, size: 18),
                label: Text(buttonText!, textDirection: TextDirection.rtl),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
