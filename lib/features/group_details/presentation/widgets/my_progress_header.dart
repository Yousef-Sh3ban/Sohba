// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                    MY PROGRESS HEADER                                      ║
// ║  عنوان تقدم المستخدم - يعرض نسبة الإتمام والنقاط                          ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/group_model.dart';

/// عنوان تقدم المستخدم الشخصي
class MyProgressHeader extends StatelessWidget {
  final double percentage;
  final int myPoints;
  final int maxPoints;
  final List<GroupModel> groups;
  final GroupModel? currentGroup;
  final void Function(GroupModel group) onSwitchGroup;

  const MyProgressHeader({
    super.key,
    required this.percentage,
    required this.myPoints,
    required this.maxPoints,
    required this.groups,
    required this.currentGroup,
    required this.onSwitchGroup,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // العنوان في المنتصف
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مهام اليوم',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),

            // الأزرار على اليمين
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => context.push('/settings'),
                ),
                if (groups.length > 1) _buildGroupMenu(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// قائمة اختيار المجموعة
  Widget _buildGroupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded, color: Colors.white),
      onSelected: (groupId) {
        final group = groups.firstWhere((g) => g.id == groupId);
        onSwitchGroup(group);
      },
      itemBuilder: (context) => groups
          .map(
            (group) => PopupMenuItem(
              value: group.id,
              child: Row(
                children: [
                  if (group.id == currentGroup?.id)
                    const Icon(
                      Icons.check,
                      size: 20,
                      color: AppTheme.primaryColor,
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  Text(group.name),
                ],
              ),
            ),
          )
          .toList(),
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
          // الصف العلوي: العنوان والنسبة
          Row(
            children: [
              Row(
                children: [
                  Text(
                    'تقدمك اليوم',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star_rounded,
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
          const SizedBox(height: 12),

          // شارة النقاط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.mainGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$myPoints / $maxPoints',
                  style: const TextStyle(
                    color: AppTheme.cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                SvgPicture.asset(
                  'assets/icons/medal.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppTheme.cardColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
