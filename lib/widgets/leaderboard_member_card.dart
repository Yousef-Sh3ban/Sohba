import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_theme.dart';
import '../models/group_member_model.dart';

/// كارت عضو في قائمة المتصدرين
///
/// يعرض صورة العضو، اسمه، شريط التقدم، والنقاط
class LeaderboardMemberCard extends StatelessWidget {
  const LeaderboardMemberCard({
    super.key,
    required this.member,
    required this.rank,
    required this.todayPoints,
    required this.maxPoints,
    required this.isCurrentUser,
    this.onTap,
  });

  /// بيانات العضو
  final GroupMemberModel member;

  /// ترتيب العضو في القائمة (يبدأ من 0)
  final int rank;

  /// نقاط العضو اليوم
  final int todayPoints;

  /// الحد الأقصى للنقاط الممكنة
  final int maxPoints;

  /// هل هذا المستخدم الحالي؟
  final bool isCurrentUser;

  /// Callback عند الضغط على الكارت
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = maxPoints > 0 ? (todayPoints / maxPoints) * 100 : 0.0;
    final displayPoints = member.totalPoints;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrentUser
              ? Border.all(color: theme.colorScheme.secondary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // ─────────────────────────────────────────────────────────────
            // صورة العضو مع ترتيبه
            // ─────────────────────────────────────────────────────────────
            _buildAvatar(),
            const SizedBox(width: 14),

            // ─────────────────────────────────────────────────────────────
            // الاسم وشريط التقدم
            // ─────────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(context),
                  const SizedBox(height: 8),
                  _buildProgressRow(percentage),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ─────────────────────────────────────────────────────────────
            // شارة النقاط
            // ─────────────────────────────────────────────────────────────
            _buildPointsBadge(displayPoints),
          ],
        ),
      ),
    );
  }

  /// بناء صورة العضو مع الكأس للأول
  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            member.userName.isNotEmpty ? member.userName[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        // كأس للمركز الأول
        if (rank == 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/cup.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// بناء صف الاسم مع شارة "أنت"
  Widget _buildNameRow(BuildContext context) {
    return Row(
      children: [
        Text(
          member.userName,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'أنت',
              style: TextStyle(fontSize: 10, color: AppTheme.accentDark),
            ),
          ),
        ],
      ],
    );
  }

  /// بناء صف شريط التقدم
  Widget _buildProgressRow(double percentage) {
    // نستخدم context للحصول على الثيم دون تمريره لأنها دالة خاصة
    // (أو يمكن استخدام Builder ولكن في بناء بسيط كهذا يمكن الاعتماد على الثيم العام أو تمرير context)
    // هنا سأفترض وجود context متاح أو سأحتاج لتمريره.
    // لكن مهلاً، هذه widget منفصلة، لا يمكنني الوصول لـ context هنا إلا إذا مررته.
    // سأقوم بتعديل استدعاء الدالة في build لتمرير context أو theme.
    // ولكن لتجنب تعقيد التعديل، سأستخدم Builder بسيط حول ProgressIndicator أو أعتمد على التغيير في build الرئيسي.
    // الأفضل: سأمرر ThemeData للدالة كما فعلت في TaskCard.

    // انتظر، أنا أستخدم multi_replace، لذا سأقوم بتعديل الاستدعاء والتعريف معاً.
    // ولكن في هذا الـ chunk أنا فقط أعدل التعريف. سأحتاج لتعديل الاستدعاء في الـ chunk الأول؟ لا، الاستدعاء ليس في الـ chunk الأول.

    // سأقوم بتعديل الاستدعاء والتعريف في steps منفصلة أو سأستخدم replace_file_content لكامل الملف إذا كان أسهل.
    // لكن multi_replace أفضل.

    // سأقوم بتغيير السطر `_buildProgressRow(percentage)` في build ليكون `_buildProgressRow(context, percentage)`
    // وهنا أستخدم context.

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    percentage >= 100
                        ? Colors.green
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme
                    .textTheme
                    .bodyMedium
                    ?.color, // أو keep textSecondary if adapted
              ),
            ),
          ],
        );
      },
    );
  }

  /// بناء شارة النقاط الذهبية
  Widget _buildPointsBadge(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.mainGold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$points',
            style: const TextStyle(
              color: AppTheme.cardColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          SvgPicture.asset(
            'assets/icons/medal.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppTheme.cardColor,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
