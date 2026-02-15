// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                    GROUP PROGRESS HEADER                                   ║
// ║  عنوان تقدم المجموعة - يعرض نسبة إتمام المجموعة                           ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_theme.dart';
import '../models/group_model.dart';
import '../screens/functions/dashboard_calculations.dart';

/// عنوان تقدم المجموعة
class GroupProgressHeader extends StatelessWidget {
  final double percentage;
  final String groupName;
  final int membersCount;
  final GroupModel? group;
  final VoidCallback? onGroupIconTap;

  const GroupProgressHeader({
    super.key,
    required this.percentage,
    required this.groupName,
    required this.membersCount,
    this.group,
    this.onGroupIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [_buildTopBar(context), _buildSummaryCard(context)],
        ),
      ),
    );
  }

  /// شريط العنوان العلوي
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // زر الإعدادات
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => context.push('/settings'),
            ),
            const Spacer(),
            // اسم المجموعة
            Text(
              groupName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // عدد الأعضاء - قابل للضغط لعرض معلومات المجموعة
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onGroupIconTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$membersCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة ملخص التقدم
  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryColor.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // الصف العلوي
          Row(
            children: [
              Row(
                children: [
                  Text(
                    'ورد اليوم',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentColor),
            ),
          ),
          const SizedBox(height: 20),

          // رسالة التشجيع
          Text(
            getProgressMessage(percentage),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
