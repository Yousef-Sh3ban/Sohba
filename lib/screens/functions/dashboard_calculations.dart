// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                    DASHBOARD CALCULATIONS                                  ║
// ║  دوال الحسابات الخاصة بلوحة التحكم                                        ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import '../../models/group_member_model.dart';
import '../../models/task_completion_model.dart';
import '../../models/task_model.dart';

/// حساب مجموع نقاط المستخدم اليوم
///
/// [tasks] - قائمة المهام
/// [myCompletions] - حالة إتمام المهام (taskId -> status)
int calculateMyTotalPoints({
  required List<TaskModel> tasks,
  required Map<String, TaskStatus> myCompletions,
}) {
  int total = 0;
  for (final task in tasks) {
    final status = myCompletions[task.id];
    if (status != null) {
      total += task.getPointsForStatus(status.value);
    }
  }
  return total;
}

/// الحد الأقصى للنقاط الممكنة (مجموع نقاط كل المهام)
///
/// [tasks] - قائمة المهام
int calculateMaxPoints(List<TaskModel> tasks) {
  return tasks.fold(0, (sum, task) => sum + task.points);
}

/// نسبة إتمام المستخدم (نقاطي / الحد الأقصى)
///
/// [tasks] - قائمة المهام
/// [myCompletions] - حالة إتمام المهام
double calculateCompletionPercentage({
  required List<TaskModel> tasks,
  required Map<String, TaskStatus> myCompletions,
}) {
  final maxPoints = calculateMaxPoints(tasks);
  if (maxPoints == 0) return 0;
  final myPoints = calculateMyTotalPoints(
    tasks: tasks,
    myCompletions: myCompletions,
  );
  return (myPoints / maxPoints) * 100;
}

/// مجموع نقاط كل أعضاء المجموعة اليوم
///
/// [members] - قائمة الأعضاء
/// [userId] - معرف المستخدم الحالي
/// [myTotalPoints] - نقاط المستخدم الحالي
/// [allCompletions] - إتمامات كل الأعضاء
int calculateGroupTotalPoints({
  required List<GroupMemberModel> members,
  required String? userId,
  required int myTotalPoints,
  required Map<String, TaskCompletionModel> allCompletions,
}) {
  int total = 0;
  for (final member in members) {
    if (member.userId == userId) {
      total += myTotalPoints; // نقاطي المحلية
    } else {
      total += allCompletions[member.userId]?.totalPoints ?? 0;
    }
  }
  return total;
}

/// الحد الأقصى لنقاط المجموعة (الحد الأقصى × عدد الأعضاء)
///
/// [tasks] - قائمة المهام
/// [membersCount] - عدد الأعضاء
int calculateGroupMaxPoints({
  required List<TaskModel> tasks,
  required int membersCount,
}) {
  return calculateMaxPoints(tasks) * membersCount;
}

/// نسبة إتمام المجموعة
///
/// [members] - قائمة الأعضاء
/// [tasks] - قائمة المهام
/// [userId] - معرف المستخدم الحالي
/// [myTotalPoints] - نقاط المستخدم الحالي
/// [allCompletions] - إتمامات كل الأعضاء
double calculateGroupPercentage({
  required List<GroupMemberModel> members,
  required List<TaskModel> tasks,
  required String? userId,
  required int myTotalPoints,
  required Map<String, TaskCompletionModel> allCompletions,
}) {
  final maxPoints = calculateGroupMaxPoints(
    tasks: tasks,
    membersCount: members.length,
  );
  if (maxPoints == 0) return 0;

  final totalPoints = calculateGroupTotalPoints(
    members: members,
    userId: userId,
    myTotalPoints: myTotalPoints,
    allCompletions: allCompletions,
  );

  return (totalPoints / maxPoints) * 100;
}

/// رسالة تشجيعية حسب نسبة الإتمام
String getProgressMessage(double percentage) {
  if (percentage >= 100) {
    return '🎉 أحسنتم! أكملتم جميع المهام';
  } else if (percentage >= 80) {
    return '🔥 رائع! لم يتبق إلا القليل';
  } else if (percentage >= 60) {
    return '💪 استمروا! أنتم في منتصف الطريق';
  } else if (percentage >= 40) {
    return '⭐ بداية جيدة! واصلوا التقدم';
  } else if (percentage >= 20) {
    return '🌱 هيا بنا! كل خطوة تحسب';
  } else if (percentage > 0) {
    return '🚀 ابدأوا رحلتكم اليوم!';
  } else {
    return '⏰ لم يبدأ أحد بعد، كونوا الأوائل!';
  }
}

/// الحصول على الحالة التالية للمهمة
/// none → partial → complete → none
TaskStatus getNextTaskStatus(TaskStatus current) {
  switch (current) {
    case TaskStatus.none:
      return TaskStatus.partial;
    case TaskStatus.partial:
      return TaskStatus.complete;
    case TaskStatus.complete:
      return TaskStatus.none;
  }
}
