// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                              APP ROUTER                                    ║
// ║  إعدادات التوجيه باستخدام GoRouter مع StatefulShellRoute                   ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/group_details/presentation/screens/task_management_screen.dart';
import '../features/home/presentation/screens/main_shell.dart';
import '../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/my_tasks/presentation/screens/my_tasks_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

/// إعداد مسارات التطبيق باستخدام GoRouter.
class AppRouter {
  AppRouter._();

  // مفتاح الـ Navigator الرئيسي
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// إنشاء router مع التحقق من حالة المستخدم.
  static GoRouter createRouter({
    required ValueNotifier<bool> authState,
    required bool hasGroups,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: authState,
      initialLocation: authState.value ? '/my-tasks' : '/welcome',
      routes: [
        // ═══════════════════════════════════════════════════════════════════
        // شاشة الترحيب (خارج الـ Shell)
        // ═══════════════════════════════════════════════════════════════════
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WelcomeScreen(),
            transitionsBuilder: _fadeTransition,
            transitionDuration: const Duration(milliseconds: 600),
          ),
        ),

        // ═══════════════════════════════════════════════════════════════════
        // الـ Shell الرئيسي مع BottomNavigationBar
        // ═══════════════════════════════════════════════════════════════════
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            // ─────────────────────────────────────────────────────────────────
            // التبويب الأول: مهامي
            // ─────────────────────────────────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-tasks',
                  name: 'my-tasks',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const MyTasksScreen(),
                    transitionsBuilder: _fadeTransition,
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
              ],
            ),

            // ─────────────────────────────────────────────────────────────────
            // التبويب الثاني: المجموعة (لوحة المتصدرين)
            // ─────────────────────────────────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/leaderboard',
                  name: 'leaderboard',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const LeaderboardScreen(),
                    transitionsBuilder: _fadeTransition,
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ═══════════════════════════════════════════════════════════════════
        // صفحات خارج الـ Shell (full-screen)
        // ═══════════════════════════════════════════════════════════════════
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const TaskManagementScreen(),
            transitionsBuilder: _slideUpTransition,
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ),

        GoRoute(
          path: '/settings',
          name: 'settings',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder: _slideUpTransition,
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ),
      ],

      // ═════════════════════════════════════════════════════════════════════
      // التوجيه التلقائي (Authentication Redirect)
      // ═════════════════════════════════════════════════════════════════════
      redirect: (context, state) {
        final isOnWelcome = state.matchedLocation == '/welcome';
        final hasUserName = authState.value;

        // إذا لم يكن لديه اسم، أرسله إلى شاشة الترحيب
        if (!hasUserName && !isOnWelcome) {
          return '/welcome';
        }

        // إذا كان لديه اسم وفي شاشة الترحيب، أرسله للرئيسية
        if (hasUserName && isOnWelcome) {
          return '/my-tasks';
        }

        return null;
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSITION BUILDERS - أنماط الانتقال
  // ═══════════════════════════════════════════════════════════════════════════

  /// انتقال Fade بسيط
  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }

  /// انتقال Slide من الأسفل
  static Widget _slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuart));

    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}
