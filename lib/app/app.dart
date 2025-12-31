import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// التطبيق الرئيسي مع إدارة الثيم.
class SohbaApp extends StatefulWidget {
  const SohbaApp({
    required this.hasUserName,
    required this.hasGroups,
    super.key,
  });

  /// هل المستخدم لديه اسم مسجل.
  final bool hasUserName;

  /// هل المستخدم لديه مجموعات.
  final bool hasGroups;

  @override
  State<SohbaApp> createState() => SohbaAppState();

  /// الوصول لحالة التطبيق من أي مكان.
  static SohbaAppState of(BuildContext context) {
    return context.findAncestorStateOfType<SohbaAppState>()!;
  }
}

/// حالة التطبيق مع إدارة الثيم.
class SohbaAppState extends State<SohbaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(themeModeKey) ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeModeIndex];
    });
  }

  /// تغيير وضع الثيم.
  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, mode.index);
  }

  /// الحصول على وضع الثيم الحالي.
  ThemeMode get themeMode => _themeMode;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter(
      hasUserName: widget.hasUserName,
      hasGroups: widget.hasGroups,
    );

    return MaterialApp.router(
      title: 'صحبة',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      locale: const Locale('ar'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
