import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const String _appVersion = '1.0.0';

  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(colors),

                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      colors,
                      title: 'التفضيلات',
                      subtitle: 'خصص طريقة عمل تطبيق حصتي حسب احتياجك.',
                    ),

                    const SizedBox(height: 12),

                    _buildThemeCard(colors),

                    const SizedBox(height: 26),

                    _buildSectionHeader(
                      colors,
                      title: 'عن التطبيق',
                      subtitle: 'معلومات وتفاصيل تطبيق حصتي.',
                    ),

                    const SizedBox(height: 12),

                    _buildInfoCard(
                      colors,
                      icon: Icons.info_outline_rounded,
                      title: 'عن حصتي',
                      subtitle:
                          'إدارة الحصص والطلاب والمجموعات والحضور والغياب من مكان واحد.',
                    ),

                    const SizedBox(height: 10),

                    _buildInfoCard(
                      colors,
                      icon: Icons.verified_rounded,
                      title: 'إصدار التطبيق',
                      subtitle: 'الإصدار الحالي $_appVersion',
                      trailing: _buildVersionBadge(colors, _appVersion),
                    ),

                    const SizedBox(height: 26),

                    _buildFooter(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.primaryContainer, 0.58)!,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'حصتي',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.05,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تحكم في مظهر التطبيق وبعض الإعدادات الأساسية.',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.4,
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

  Widget _buildSectionHeader(
    ColorScheme colors, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            height: 1.35,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(ColorScheme colors) {
    final icon = isDarkMode
        ? Icons.dark_mode_rounded
        : Icons.light_mode_rounded;

    final title = isDarkMode ? 'الوضع الليلي' : 'الوضع النهاري';

    final subtitle = isDarkMode
        ? 'الوضع الليلي مفعل حاليًا'
        : 'الوضع النهاري مفعل حاليًا';

    return _buildTile(
      colors,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onThemeToggle,
      trailing: Switch.adaptive(
        value: isDarkMode,
        onChanged: (_) => onThemeToggle(),
      ),
    );
  }

  Widget _buildInfoCard(
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return _buildTile(
      colors,
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }

  Widget _buildVersionBadge(ColorScheme colors, String version) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        version,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: colors.primary,
        ),
      ),
    );
  }

  Widget _buildTile(
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        splashColor: colors.primary.withValues(alpha: 0.04),
        highlightColor: colors.primary.withValues(alpha: 0.02),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 22, color: colors.primary),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (trailing != null)
                trailing
              else if (onTap != null)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school_rounded, size: 19, color: colors.primary),
        ),
        const SizedBox(height: 9),
        Text(
          'حصتي',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'إدارة الحصص بطريقة أبسط',
          style: TextStyle(fontSize: 9, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
