// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                         MY TASKS SCREEN                                    ║
// ║  صفحة مهامي - عرض المهام اليومية للمستخدم                                  ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../widgets/animated_bottom_sheet.dart';
import '../models/task_completion_model.dart';
import 'dashboard_controller.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/join_group_sheet.dart';
import '../widgets/my_progress_header.dart';
import '../widgets/task_card.dart';

/// صفحة مهامي - عرض المهام اليومية مع إمكانية تسجيل الإتمام
class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // الـ Header مع نسبة التقدم
            MyProgressHeader(
                  percentage: controller.completionPercentage,
                  myPoints: controller.myTotalPoints,
                  maxPoints: controller.maxPoints,
                  groups: controller.groups,
                  currentGroup: controller.currentGroup,
                  onSwitchGroup: controller.switchGroup,
                  onCreateGroup: () =>
                      _showCreateGroupSheet(context, controller),
                  onJoinGroup: () => _showJoinGroupSheet(context, controller),
                  onLeaveGroup: () =>
                      _showLeaveGroupConfirmation(context, controller),
                )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .slideY(
                  begin: -0.05,
                  end: 0,
                  duration: 1000.ms,
                  curve: Curves.easeOutCubic,
                ),

            // قائمة المهام
            Expanded(
              child: controller.tasks.isEmpty
                  ? _buildEmptyState(context, controller)
                  : _buildTasksList(context, controller),
            ),
          ],
        );
      },
    );
  }

  /// بناء قائمة المهام
  Widget _buildTasksList(BuildContext context, DashboardController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.tasks.length,
      itemBuilder: (context, index) {
        final task = controller.tasks[index];
        final status = controller.myCompletions[task.id] ?? TaskStatus.none;

        return TaskCard(
              task: task,
              status: status,
              onStatusChange: () => controller.updateTaskStatus(
                task.id,
                controller.getNextStatus(status),
              ),
            )
            .animate()
            .fadeIn(
              duration: 800.ms,
              delay: (index * 120).ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.15,
              end: 0,
              duration: 900.ms,
              delay: (index * 120).ms,
              curve: Curves.easeOutQuart,
            )
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 800.ms,
              delay: (index * 120).ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }

  /// حالة عدم وجود مهام
  Widget _buildEmptyState(
    BuildContext context,
    DashboardController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد مهام بعد',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            controller.isAdmin
                ? 'أضف أول مهمة لمجموعتك واجعلوا يومكم مليئًا بالعبادات!'
                : 'انتظر حتى يضيف المسؤول المهام للمجموعة',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          if (controller.isAdmin) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف مهمة'),
              onPressed: () => context.push('/tasks'),
            ),
          ],
        ],
      ),
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

  /// عرض حوار تأكيد المغادرة
  void _showLeaveGroupConfirmation(
    BuildContext context,
    DashboardController controller,
  ) {
    final groupName = controller.currentGroup?.name ?? 'المجموعة';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: Text(
          'هل أنت متأكد من مغادرة "$groupName"؟\n\nستفقد وصولك للمجموعة ونقاطك فيها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await controller.leaveCurrentGroup();
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم مغادرة المجموعة بنجاح')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
  }
}
