import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/group_details/presentation/screens/group_dashboard_screen.dart';
import '../features/group_details/presentation/screens/task_management_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

/// إعداد مسارات التطبيق باستخدام GoRouter.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// إنشاء router مع التحقق من حالة المستخدم.
  static GoRouter createRouter({
    required bool hasUserName,
    required bool hasGroups,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: hasUserName ? '/' : '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const GroupDashboardScreen(),
          routes: [
            GoRoute(
              path: 'tasks',
              name: 'tasks',
              builder: (context, state) => const TaskManagementScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      redirect: (context, state) {
        final isOnWelcome = state.matchedLocation == '/welcome';

        // إذا لم يكن لديه اسم، أرسله إلى شاشة الترحيب
        if (!hasUserName && !isOnWelcome) {
          return '/welcome';
        }

        // إذا كان لديه اسم وفي شاشة الترحيب، أرسله للرئيسية
        if (hasUserName && isOnWelcome) {
          return '/';
        }

        return null;
      },
    );
  }
}
