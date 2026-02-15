// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                       LEADERBOARD SCREEN                                   ║
// ║  صفحة لوحة المتصدرين - عرض ترتيب الأعضاء حسب النقاط                        ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/group_member_model.dart';
import 'dashboard_controller.dart';
import '../widgets/group_progress_header.dart';
import '../widgets/leaderboard_member_card.dart';
import '../widgets/member_profile_sheet.dart';
import '../widgets/group_info_sheet.dart';

/// صفحة لوحة المتصدرين - عرض ترتيب الأعضاء حسب نقاطهم اليومية
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // الـ Header مع نسبة تقدم المجموعة
            GroupProgressHeader(
                  percentage: controller.groupPercentage,
                  groupName: controller.currentGroup?.name ?? 'المجموعة',
                  membersCount: controller.members.length,
                  group: controller.currentGroup,
                  onGroupIconTap: controller.currentGroup != null
                      ? () => _showGroupInfo(context, controller.currentGroup!)
                      : null,
                )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .slideY(
                  begin: -0.05,
                  end: 0,
                  duration: 1000.ms,
                  curve: Curves.easeOutCubic,
                ),

            // قائمة المتصدرين
            Expanded(child: _buildLeaderboardList(context, controller)),
          ],
        );
      },
    );
  }

  /// بناء قائمة المتصدرين مرتبة حسب النقاط
  Widget _buildLeaderboardList(
    BuildContext context,
    DashboardController controller,
  ) {
    final sortedMembers = _getSortedMembers(controller);
    final maxPoints = controller.maxPoints;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMembers.length,
      itemBuilder: (context, index) {
        final member = sortedMembers[index];
        final isCurrentUser = member.userId == controller.userId;

        final memberPoints = isCurrentUser
            ? controller.myTotalPoints
            : (controller.allCompletions[member.userId]?.totalPoints ?? 0);

        return LeaderboardMemberCard(
              member: member,
              rank: index,
              todayPoints: memberPoints,
              maxPoints: maxPoints,
              isCurrentUser: isCurrentUser,
              onTap: () => _showMemberProfile(
                context,
                member,
                memberPoints,
                maxPoints,
                isCurrentUser,
              ),
            )
            .animate()
            .fadeIn(
              duration: 1000.ms,
              delay: (index * 150).ms,
              curve: Curves.easeOut,
            )
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 1200.ms,
              delay: (index * 150).ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  /// ترتيب الأعضاء حسب النقاط (من الأعلى للأقل)
  List<GroupMemberModel> _getSortedMembers(DashboardController controller) {
    final sortedMembers = [...controller.members];

    sortedMembers.sort((a, b) {
      final aPoints = a.userId == controller.userId
          ? controller.myTotalPoints
          : (controller.allCompletions[a.userId]?.totalPoints ?? 0);
      final bPoints = b.userId == controller.userId
          ? controller.myTotalPoints
          : (controller.allCompletions[b.userId]?.totalPoints ?? 0);
      return bPoints.compareTo(aPoints);
    });

    return sortedMembers;
  }

  /// عرض ملف العضو في Bottom Sheet
  void _showMemberProfile(
    BuildContext context,
    GroupMemberModel member,
    int todayPoints,
    int maxPoints,
    bool isCurrentUser,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // أنيميشن بطيء وسلس للـ bottom sheet (premium feel)
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
      builder: (ctx) => MemberProfileSheet(
        member: member,
        todayPoints: todayPoints,
        maxPoints: maxPoints,
        isCurrentUser: isCurrentUser,
      ),
    );
  }

  /// عرض معلومات المجموعة وكود الدعوة في Bottom Sheet
  void _showGroupInfo(BuildContext context, group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // أنيميشن بطيء وسلس للـ bottom sheet (premium feel)
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
      builder: (ctx) => GroupInfoSheet(group: group),
    );
  }
}
