// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                           MAIN SHELL                                       ║
// ║  الـ Shell الرئيسي - يحتوي على BottomNav ويعرض الصفحات الفرعية             ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/animated_bottom_sheet.dart';
import '../../../group_details/presentation/screens/dashboard_controller.dart';
import '../../../group_details/presentation/widgets/create_group_sheet.dart';
import '../../../group_details/presentation/widgets/custom_bottom_nav.dart';
import '../../../group_details/presentation/widgets/empty_groups_view.dart';
import '../../../group_details/presentation/widgets/join_group_sheet.dart';

/// الـ Shell الرئيسي للتطبيق
/// يحتوي على BottomNavigationBar ويعرض الصفحات الفرعية (مهامي / المجموعة)
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        // حالة التحميل
        if (controller.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // لا توجد مجموعات - عرض شاشة إنشاء/انضمام
        if (controller.groups.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: EmptyGroupsView(
              onCreateGroup: () => _showCreateGroupSheet(context, controller),
              onJoinGroup: () => _showJoinGroupSheet(context, controller),
            ),
          );
        }

        // عرض الصفحة العادية مع BottomNav
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: navigationShell,
          bottomNavigationBar: CustomBottomNav(
            currentIndex: navigationShell.currentIndex,
            onIndexChanged: (index) => _onNavTap(index),
          ),
          floatingActionButton: _buildFAB(context, controller),
        );
      },
    );
  }

  /// التنقل بين التبويبات
  void _onNavTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// زر الإضافة العائم (للأدمن فقط في صفحة مهامي)
  Widget? _buildFAB(BuildContext context, DashboardController controller) {
    // الزر يظهر فقط في صفحة "مهامي" (index 0) وللأدمن فقط
    if (navigationShell.currentIndex != 0 || !controller.isAdmin) {
      return null;
    }

    return FloatingActionButton(
      backgroundColor: AppTheme.primaryColor,
      onPressed: () => context.push('/tasks'),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }

  /// عرض ورقة إنشاء مجموعة جديدة
  void _showCreateGroupSheet(
    BuildContext context,
    DashboardController controller,
  ) {
    showAnimatedBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => CreateGroupSheet(
        onGroupCreated: (group) {
          Navigator.pop(ctx);
          controller.loadData();
        },
      ),
    );
  }

  /// عرض ورقة الانضمام لمجموعة
  void _showJoinGroupSheet(
    BuildContext context,
    DashboardController controller,
  ) {
    showAnimatedBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => JoinGroupSheet(
        onGroupJoined: (group) {
          Navigator.pop(ctx);
          controller.loadData();
        },
      ),
    );
  }
}
