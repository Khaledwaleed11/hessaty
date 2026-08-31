import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    this.title = 'حدث خطأ',
    this.message = 'من فضلك تحقق من الاتصال بالإنترنت وحاول مرة أخرى.',
    this.buttonText = 'حاول مرة أخرى',
    this.icon = Icons.cloud_off_rounded,
    required this.onRetry,
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: colors.error),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
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
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
