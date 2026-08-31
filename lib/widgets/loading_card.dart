import 'package:flutter/material.dart';

enum LoadingCardType { schedule, group, student }

class LoadingCard extends StatelessWidget {
  final LoadingCardType type;
  final int itemCount;

  const LoadingCard({
    super.key,
    this.type = LoadingCardType.student,
    this.itemCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LoadingItem(type: type),
        ),
      ),
    );
  }
}

class _LoadingItem extends StatelessWidget {
  final LoadingCardType type;

  const _LoadingItem({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingCardType.schedule:
        return _buildScheduleLoading(context);

      case LoadingCardType.group:
        return _buildGroupLoading(context);

      case LoadingCardType.student:
        return _buildStudentLoading(context);
    }
  }

  Widget _buildScheduleLoading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _card(
      context,
      child: Row(
        children: [
          _box(context, width: 62, height: 62, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(context, width: 90, height: 10),
                const SizedBox(height: 9),
                _box(context, width: double.infinity, height: 14),
                const SizedBox(height: 8),
                _box(context, width: 130, height: 9),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _box(context, width: 12, height: 12, radius: 4),
        ],
      ),
      colors: colors,
    );
  }

  Widget _buildGroupLoading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _card(
      context,
      child: Row(
        children: [
          _box(context, width: 50, height: 50, radius: 15),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(context, width: 130, height: 13),
                const SizedBox(height: 8),
                _box(context, width: 90, height: 9),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _box(context, width: 75, height: 8),
                    const SizedBox(width: 12),
                    _box(context, width: 65, height: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _box(context, width: 12, height: 12, radius: 4),
        ],
      ),
      colors: colors,
    );
  }

  Widget _buildStudentLoading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _card(
      context,
      child: Row(
        children: [
          _box(context, width: 48, height: 48, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(context, width: 140, height: 13),
                const SizedBox(height: 8),
                _box(context, width: 90, height: 9),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _box(context, width: 34, height: 34, radius: 10),
        ],
      ),
      colors: colors,
    );
  }

  Widget _card(
    BuildContext context, {
    required Widget child,
    required ColorScheme colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: child,
    );
  }

  Widget _box(
    BuildContext context, {
    required double width,
    required double height,
    double radius = 7,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
