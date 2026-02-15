// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                    DASHBOARD CONTROLLER                                    ║
// ║  متحكم لوحة التحكم - يدير الحالة والبيانات                                ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../models/task_completion_model.dart';
import '../models/task_model.dart';
import 'functions/dashboard_calculations.dart';
import 'functions/dashboard_data_service.dart';

/// متحكم لوحة التحكم
/// يفصل state management عن واجهة المستخدم
class DashboardController extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE VARIABLES - متغيرات الحالة
  // ═══════════════════════════════════════════════════════════════════════════

  // بيانات المجموعات
  List<GroupModel> _groups = [];
  GroupModel? _currentGroup;

  // بيانات المهام والأعضاء
  List<TaskModel> _tasks = [];
  List<GroupMemberModel> _members = [];

  // حالة إتمام المهام
  Map<String, TaskStatus> _myCompletions = {};
  Map<String, TaskCompletionModel> _allCompletions = {};

  // معلومات المستخدم والتحميل
  String? _userId;
  bool _isLoading = true;
  int _currentNavIndex = 0;

  // الـ Subscriptions للـ Real-time
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _completionsSubscription;
  StreamSubscription? _membersSubscription;

  // للتحكم في التحديثات
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, TaskStatus> _lastSentStatus = {};
  int _pendingUpdatesCount = 0; // عداد التحديثات المعلقة

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS - واجهات القراءة
  // ═══════════════════════════════════════════════════════════════════════════

  List<GroupModel> get groups => _groups;
  GroupModel? get currentGroup => _currentGroup;
  List<TaskModel> get tasks => _tasks;
  List<GroupMemberModel> get members => _members;
  Map<String, TaskStatus> get myCompletions => _myCompletions;
  Map<String, TaskCompletionModel> get allCompletions => _allCompletions;
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  int get currentNavIndex => _currentNavIndex;

  /// هل المستخدم أدمن المجموعة؟
  bool get isAdmin =>
      _currentGroup != null && _currentGroup!.adminId == _userId;

  // ═══════════════════════════════════════════════════════════════════════════
  // CALCULATIONS - الحسابات
  // ═══════════════════════════════════════════════════════════════════════════

  int get myTotalPoints =>
      calculateMyTotalPoints(tasks: _tasks, myCompletions: _myCompletions);

  int get maxPoints => calculateMaxPoints(_tasks);

  double get completionPercentage => calculateCompletionPercentage(
    tasks: _tasks,
    myCompletions: _myCompletions,
  );

  double get groupPercentage => calculateGroupPercentage(
    members: _members,
    tasks: _tasks,
    userId: _userId,
    myTotalPoints: myTotalPoints,
    allCompletions: _allCompletions,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION - التنقل
  // ═══════════════════════════════════════════════════════════════════════════

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING - تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحميل البيانات الأولية
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final result = await DashboardDataService.loadInitialData();

    if (!result.success) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _userId = result.userId;

    if (result.groups.isEmpty) {
      _groups = [];
      _currentGroup = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _groups = result.groups;
    _currentGroup = result.activeGroup;
    notifyListeners();

    _listenToGroupData(result.activeGroup!.id);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REAL-TIME LISTENERS - المستمعون للتحديثات
  // ═══════════════════════════════════════════════════════════════════════════

  void _listenToGroupData(String groupId) {
    _cancelSubscriptions();

    // المهام
    _tasksSubscription = DashboardDataService.watchTasks(groupId).listen((
      tasks,
    ) {
      _tasks = tasks;
      _isLoading = false;
      notifyListeners();
    });

    // الإتمامات
    _completionsSubscription = DashboardDataService.watchCompletions(groupId)
        .listen((completions) {
          final completionsMap = DashboardDataService.completionsToMap(
            completions,
          );
          _allCompletions = completionsMap;
          // تحديث حالتي فقط إذا لم تكن هناك تحديثات معلقة
          if (_pendingUpdatesCount == 0 &&
              _userId != null &&
              completionsMap.containsKey(_userId)) {
            _myCompletions = completionsMap[_userId]!.tasks;
            // تهيئة آخر حالة مرسلة بالقيم الحالية من Firestore
            _lastSentStatus.clear();
            _lastSentStatus.addAll(completionsMap[_userId]!.tasks);
          }
          notifyListeners();
        });

    // الأعضاء
    _membersSubscription = DashboardDataService.watchMembers(groupId).listen((
      members,
    ) {
      _members = members;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _tasksSubscription?.cancel();
    _completionsSubscription?.cancel();
    _membersSubscription?.cancel();
  }

  /// مسح حالة التحديثات المعلقة
  void _clearPendingUpdates() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _lastSentStatus.clear();
    _pendingUpdatesCount = 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP MANAGEMENT - إدارة المجموعات
  // ═══════════════════════════════════════════════════════════════════════════

  /// التبديل إلى مجموعة أخرى
  Future<void> switchGroup(GroupModel group) async {
    // مسح التحديثات المعلقة للمجموعة السابقة
    _clearPendingUpdates();
    
    await DashboardDataService.saveLastGroup(group.id);
    _currentGroup = group;
    notifyListeners();
    _listenToGroupData(group.id);
  }

  /// مغادرة المجموعة الحالية
  Future<bool> leaveCurrentGroup() async {
    if (_currentGroup == null || _userId == null) return false;

    try {
      await AppServices.instance.groupRepository.leaveGroup(
        _currentGroup!.id,
        _userId!,
      );

      // إعادة تحميل البيانات (ستحصل على المجموعات المتبقية)
      await loadData();
      return true;
    } catch (e) {
      developer.log('Error leaving group: $e', name: 'sohba.dashboard');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASK UPDATES - تحديث المهام
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث حالة مهمة
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    if (_currentGroup == null || _userId == null) return;

    // تحديث محلي فوري
    _myCompletions[taskId] = newStatus;
    notifyListeners();

    // إلغاء الـ timer السابق لهذه المهمة فقط (لا نقلل العداد لأن timer جديد سيحل محله)
    final hadPreviousTimer = _debounceTimers.containsKey(taskId);
    _debounceTimers[taskId]?.cancel();
    
    // زيادة العداد فقط إذا لم يكن هناك timer سابق لهذه المهمة
    if (!hadPreviousTimer) {
      _pendingUpdatesCount++;
    }
    
    // حفظ المجموعة والمستخدم الحاليين لاستخدامهم لاحقاً
    final groupId = _currentGroup!.id;
    final userId = _userId!;
    
    // تأخير الإرسال لـ Firestore
    _debounceTimers[taskId] = Timer(const Duration(milliseconds: 500), () async {
      try {
        // التحقق من أن المجموعة لم تتغير
        if (_currentGroup?.id != groupId) {
          return;
        }
        
        // الحصول على آخر حالة مرسلة لهذه المهمة
        final lastSent = _lastSentStatus[taskId] ?? TaskStatus.none;
        final currentStatus = _myCompletions[taskId] ?? TaskStatus.none;
        
        // لا ترسل إذا الحالة لم تتغير عن آخر إرسال
        if (lastSent == currentStatus) {
          return;
        }
        
        final task = _tasks.firstWhere((t) => t.id == taskId, orElse: () => throw Exception('Task not found'));
        await AppServices.instance.taskRepository.updateTaskCompletion(
          groupId: groupId,
          userId: userId,
          taskId: taskId,
          status: currentStatus,
          taskPoints: task.points,
          previousStatus: lastSent,
        );
        
        // تحديث آخر حالة تم إرسالها
        _lastSentStatus[taskId] = currentStatus;
      } catch (e) {
        developer.log('Error updating task: $e', name: 'sohba.dashboard');
        // في حالة الخطأ، نعيد الحالة المحلية للحالة المرسلة الأخيرة
        if (_lastSentStatus.containsKey(taskId)) {
          _myCompletions[taskId] = _lastSentStatus[taskId]!;
          notifyListeners();
        }
      } finally {
        _debounceTimers.remove(taskId);
        _pendingUpdatesCount--;
        if (_pendingUpdatesCount < 0) _pendingUpdatesCount = 0;
      }
    });
  }

  /// الحصول على الحالة التالية للمهمة
  TaskStatus getNextStatus(TaskStatus current) => getNextTaskStatus(current);

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPOSE - التنظيف
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _cancelSubscriptions();
    _clearPendingUpdates();
    super.dispose();
  }
}
