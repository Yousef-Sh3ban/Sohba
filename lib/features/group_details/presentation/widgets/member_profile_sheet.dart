import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/group_member_model.dart';

/// Bottom Sheet لعرض معلومات العضو.
class MemberProfileSheet extends StatelessWidget {
  final GroupMemberModel member;
  final int todayPoints;
  final int maxPoints;
  final bool isCurrentUser;

  const MemberProfileSheet({
    super.key,
    required this.member,
    required this.todayPoints,
    required this.maxPoints,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxPoints > 0 ? (todayPoints / maxPoints) * 100 : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      member.userName.isNotEmpty ? member.userName[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  if (isCurrentUser)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          // Name
          Text(
                member.userName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate(delay: 150.ms)
              .fadeIn(duration: 500.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutQuart,
              ),
          if (isCurrentUser)
            Text(
              'أنت',
              style: TextStyle(color: AppTheme.accentColor, fontSize: 14),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              _buildStatItem(
                context,
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
                value: '${member.currentStreak}',
                label: '    Streak    ',
              ),
              Spacer(),
              _buildDivider(),
              Spacer(),
              _buildStatItem(
                context,
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber,
                value: '${member.longestStreak}',
                label: ' أطول سلسلة ',
              ),
              Spacer(),
              _buildDivider(),
              Spacer(),
              _buildStatItem(
                context,
                customIcon: SvgPicture.asset(
                  'assets/icons/medal.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppTheme.mainGold,
                    BlendMode.srcIn,
                  ),
                ),
                value: '${member.totalPoints}',
                label: 'إجمالي النقاط',
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Progress
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تقدم اليوم',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage / 100),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        percentage >= 100 ? Colors.green : AppTheme.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$todayPoints / $maxPoints نقطة',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Join Date
          Text(
            'انضم ${_formatDate(member.joinedAt)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    IconData? icon,
    Color? iconColor,
    Widget? customIcon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        if (customIcon != null)
          customIcon
        else
          Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 50, width: 1, color: Colors.grey[300]);
  }

  String _formatDate(DateTime date) {
    // استخدام تنسيق بسيط بدون locale
    final day = date.day;
    final month = _getArabicMonth(date.month);
    final year = date.year;
    return '$day $month $year';
  }

  String _getArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
