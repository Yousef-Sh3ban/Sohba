// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                              APP ROUTER                                    ║
// ║  إعدادات التوجيه باستخدام GoRouter مع StatefulShellRoute                   ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/task_management_screen.dart';
import 'screens/main_shell.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/my_tasks_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

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
      initialLocation: '/splash',
      routes: [
        // ═══════════════════════════════════════════════════════════════════
        // شاشة البداية (Splash)
        // ═══════════════════════════════════════════════════════════════════
        GoRoute(
          path: '/splash',
          name: 'splash',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder: _fadeTransition,
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),

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
                    // UniqueKey لإعادة بناء الصفحة وتشغيل الأنميشن عند كل زيارة
                    key: UniqueKey(),
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
                    // UniqueKey لإعادة بناء الصفحة وتشغيل الأنميشن عند كل زيارة
                    key: UniqueKey(),
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
        final location = state.matchedLocation;
        final isOnSplash = location == '/splash';
        final isOnWelcome = location == '/welcome';
        final hasUserName = authState.value;

        // السماح بشاشة البداية دائماً
        if (isOnSplash) {
          return null;
        }

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
