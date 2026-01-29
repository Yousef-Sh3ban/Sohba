// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                    DASHBOARD DATA SERVICE                                  ║
// ║  خدمة البيانات للوحة التحكم - تتعامل مع Firestore و SharedPreferences     ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'dart:async';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../data/models/group_member_model.dart';
import '../../../../../data/models/group_model.dart';
import '../../../../../data/models/task_completion_model.dart';
import '../../../../../data/models/task_model.dart';

/// نتيجة تحميل البيانات الأولية
class InitialDataResult {
  final String? userId;
  final List<GroupModel> groups;
  final GroupModel? activeGroup;
  final bool success;
  final String? error;

  InitialDataResult({
    this.userId,
    this.groups = const [],
    this.activeGroup,
    this.success = true,
    this.error,
  });

  factory InitialDataResult.empty() =>
      InitialDataResult(userId: null, groups: [], activeGroup: null);

  factory InitialDataResult.failure(String error) =>
      InitialDataResult(success: false, error: error);
}

/// خدمة البيانات للوحة التحكم
/// تفصل منطق البيانات عن واجهة المستخدم
class DashboardDataService {
  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING - تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل البيانات الأولية من SharedPreferences و Firestore
  static Future<InitialDataResult> loadInitialData() async {
    try {
      // 1️⃣ قراءة البيانات المحفوظة محلياً
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(deviceIdKey);
      final savedGroupId = prefs.getString(lastGroupIdKey);
      final groupIds = prefs.getStringList(userGroupIdsKey) ?? [];

      // 2️⃣ التحقق من وجود userId
      if (userId == null) {
        return InitialDataResult.empty();
      }

      // 3️⃣ التحقق من وجود مجموعات
      if (groupIds.isEmpty) {
        return InitialDataResult(userId: userId);
      }

      // 4️⃣ جلب بيانات كل مجموعة من Firestore
      final groups = <GroupModel>[];
      for (final groupId in groupIds) {
        final group = await AppServices.instance.groupRepository.getGroup(
          groupId,
        );
        if (group != null) {
          groups.add(group);
        }
      }

      // 5️⃣ التحقق من نجاح الجلب
      if (groups.isEmpty) {
        return InitialDataResult(userId: userId);
      }

      // 6️⃣ تحديد المجموعة النشطة
      GroupModel? activeGroup;
      if (savedGroupId != null) {
        activeGroup = groups.where((g) => g.id == savedGroupId).firstOrNull;
      }
      activeGroup ??= groups.first;

      return InitialDataResult(
        userId: userId,
        groups: groups,
        activeGroup: activeGroup,
      );
    } catch (e) {
      developer.log('Error loading data: $e', name: 'sohba.dashboard');
      return InitialDataResult.failure(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REAL-TIME STREAMS - التدفقات المباشرة
  // ═══════════════════════════════════════════════════════════════════════════

  /// الحصول على stream المهام
  static Stream<List<TaskModel>> watchTasks(String groupId) {
    return AppServices.instance.taskRepository.watchTasks(groupId);
  }

  /// الحصول على stream إتمامات المهام
  static Stream<List<TaskCompletionModel>> watchCompletions(String groupId) {
    return AppServices.instance.taskRepository.watchTodayCompletions(groupId);
  }

  /// الحصول على stream الأعضاء
  static Stream<List<GroupMemberModel>> watchMembers(String groupId) {
    return AppServices.instance.groupRepository.watchMembers(groupId);
  }

  /// تحويل قائمة الإتمامات إلى Map
  static Map<String, TaskCompletionModel> completionsToMap(
    List<TaskCompletionModel> completions,
  ) {
    final map = <String, TaskCompletionModel>{};
    for (final c in completions) {
      map[c.userId] = c;
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP MANAGEMENT - إدارة المجموعات
  // ═══════════════════════════════════════════════════════════════════════════

  /// حفظ آخر مجموعة محددة
  static Future<void> saveLastGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastGroupIdKey, groupId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASK UPDATES - تحديث المهام
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث حالة مهمة في Firestore
  static Future<bool> updateTaskStatus({
    required String groupId,
    required String userId,
    required String taskId,
    required TaskStatus status,
    required int taskPoints,
  }) async {
    try {
      await AppServices.instance.taskRepository.updateTaskCompletion(
        groupId: groupId,
        userId: userId,
        taskId: taskId,
        status: status,
        taskPoints: taskPoints,
      );
      return true;
    } catch (e) {
      developer.log('Error updating task: $e', name: 'sohba.dashboard');
      return false;
    }
  }
}
