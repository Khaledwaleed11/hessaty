import 'package:flutter/material.dart';

import 'package:hessaty/screens/level_screen.dart';
import 'package:hessaty/screens/groups_screen.dart';
import 'package:hessaty/screens/schedule_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const SettingsScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDark =
        theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        theme.scaffoldBackgroundColor,

        // =====================================================
        // App Bar
        // =====================================================

        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor:
          theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: false,
        ),

        // =====================================================
        // Body
        // =====================================================

        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [

              // =================================================
              // Header
              // =================================================

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius:
                  BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary
                          .withValues(alpha: 0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    // Icon
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.onPrimary
                            .withValues(alpha: 0.15),
                        borderRadius:
                        BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: colors.onPrimary,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حصتي',
                            style: TextStyle(
                              color:
                              colors.onPrimary,
                              fontSize: 21,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'إدارة التطبيق والإعدادات',
                            style: TextStyle(
                              color: colors.onPrimary
                                  .withValues(
                                alpha: 0.80,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // Appearance
              // =================================================

              _SectionTitle(
                title: 'المظهر',
                icon: Icons.palette_outlined,
              ),

              const SizedBox(height: 10),

              _SettingCard(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: 'الوضع الليلي',
                subtitle: isDark
                    ? 'الوضع الداكن مفعل'
                    : 'الوضع الفاتح مفعل',
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (_) {
                    onThemeToggle();
                  },
                ),
                onTap: onThemeToggle,
              ),

              const SizedBox(height: 26),

              // =================================================
              // Management
              // =================================================

              _SectionTitle(
                title: 'إدارة التطبيق',
                icon:
                Icons.manage_accounts_outlined,
              ),

              const SizedBox(height: 10),

              // =================================================
              // Levels
              // =================================================

              _SettingCard(
                icon: Icons.layers_rounded,
                title: 'المستويات',
                subtitle:
                'إضافة وتعديل وحذف المستويات والمصاريف',
                trailing: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const LevelsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // =================================================
              // Groups
              // =================================================

              _SettingCard(
                icon: Icons.groups_rounded,
                title: 'الجروبات',
                subtitle:
                'إدارة مجموعات الطلاب',
                trailing: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const GroupsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // =================================================
              // Schedule
              // =================================================

              _SettingCard(
                icon:
                Icons.calendar_month_rounded,
                title: 'الجدول الدراسي',
                subtitle:
                'إدارة مواعيد الحصص والجداول',
                trailing: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ScheduleScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 26),

              // =================================================
              // About
              // =================================================

              _SectionTitle(
                title: 'عن التطبيق',
                icon: Icons.info_outline_rounded,
              ),

              const SizedBox(height: 10),

              // About App
              _SettingCard(
                icon: Icons.school_rounded,
                title: 'حصتي',
                subtitle:
                'مساعد المدرس لإدارة الطلاب والحصص',
                trailing: const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                ),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: 12),

              // Version
              _SettingCard(
                icon: Icons.code_rounded,
                title: 'إصدار التطبيق',
                subtitle: 'Version 1.0.0',
                trailing:
                const SizedBox.shrink(),
                onTap: null,
              ),

              const SizedBox(height: 30),

              // =================================================
              // Footer
              // =================================================

              Center(
                child: Text(
                  'حصتي • لإدارة حصصك وطلابك بسهولة',
                  style: TextStyle(
                    color: theme
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // About Dialog
  // ===========================================================

  void _showAboutDialog(
      BuildContext context,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        final colors =
            Theme.of(context).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),
          title: Row(
            children: [

              Container(
                padding:
                const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: colors.primary,
                ),
              ),

              const SizedBox(width: 12),

              const Text(
                'عن حصتي',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          content: const Text(
            'حصتي هو تطبيق يساعد المدرس على إدارة الطلاب '
                'والجروبات والحصص والحضور والمصاريف والامتحانات '
                'من مكان واحد بسهولة.',
            style: TextStyle(
              height: 1.7,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'حسنًا',
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================
// Section Title
// =============================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    return Row(
      children: [

        Icon(
          icon,
          size: 19,
          color: colors.primary,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// Setting Card
// =============================================================

class _SettingCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius:
      BorderRadius.circular(20),

      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(20),

        child: Container(
          padding:
          const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(20),

            border: Border.all(
              color: colors.outline
                  .withValues(
                alpha: 0.10,
              ),
            ),
          ),

          child: Row(
            children: [

              // =================================================
              // Icon
              // =================================================

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 14),

              // =================================================
              // Text
              // =================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // =================================================
              // Trailing
              // =================================================

              if (trailing != null)
                trailing!,
            ],
          ),
        ),
      ),
    );
  }
}