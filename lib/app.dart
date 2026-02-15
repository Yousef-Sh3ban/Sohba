import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_constants.dart';
import 'services/app_services.dart';
import 'services/connectivity_service.dart';
import 'screens/dashboard_controller.dart';
import 'router.dart';
import 'app_theme.dart';
import 'widgets/no_internet_banner.dart';

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
      authState: AppServices.instance.authState,
      hasGroups: widget.hasGroups,
    );

    return ChangeNotifierProvider(
      create: (_) => DashboardController()..loadData(),
      child: MaterialApp.router(
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
          return Directionality(
            textDirection: TextDirection.rtl,
            child: _ConnectivityWrapper(child: child!),
          );
        },
      ),
    );
  }
}

/// Wrapper يستمع لحالة الاتصال ويعرض البانر المناسب.
class _ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const _ConnectivityWrapper({required this.child});

  @override
  State<_ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<_ConnectivityWrapper> {
  bool _isConnected = true;
  bool _showConnectedBanner = false;

  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات الاتصال
    ConnectivityService.instance.connectivityStream.listen((isConnected) {
      setState(() {
        final wasDisconnected = !_isConnected;
        _isConnected = isConnected;

        // عند عودة الاتصال بعد انقطاع، أظهر بانر "تم الاتصال" لثانيتين
        if (isConnected && wasDisconnected) {
          _showConnectedBanner = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showConnectedBanner = false;
              });
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // البانر يظهر فقط عند انقطاع الاتصال أو عودته
        if (!_isConnected)
          const NoInternetBanner()
        else if (_showConnectedBanner)
          const ConnectedBanner(),
      ],
    );
  }
}
