import 'package:flutter/material.dart';
import 'package:hessaty/screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox('groups');
  await Hive.openBox('students');
  await Hive.openBox('schedules');
  await Hive.openBox('attendance');
  await Hive.openBox('settings');

  final settingsBox = Hive.box('settings');

  final isDarkMode = settingsBox.get('isDarkMode', defaultValue: false) as bool;

  runApp(HessatyApp(isDarkMode: isDarkMode));
}

class HessatyApp extends StatefulWidget {
  final bool isDarkMode;

  const HessatyApp({super.key, required this.isDarkMode});

  @override
  State<HessatyApp> createState() => _HessatyAppState();
}

class _HessatyAppState extends State<HessatyApp> {
  late ThemeMode themeMode;

  @override
  void initState() {
    super.initState();

    themeMode = widget.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    setState(() {
      themeMode = newMode;
    });

    await Hive.box('settings').put('isDarkMode', newMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'حصتي',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      locale: const Locale('ar'),

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },

      home: SplashScreen(
        isDarkMode: themeMode == ThemeMode.dark,
        onThemeToggle: toggleTheme,
      ),
    );
  }
}
