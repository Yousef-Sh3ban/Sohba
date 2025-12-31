import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/fajr_time_service.dart';
import '../models/task_completion_model.dart';
import '../models/task_model.dart';

/// Repository للتعامل مع المهام وإنجازاتها في Firestore.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// مرجع collection المجموعات.
  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('groups');

  // ==================== المهام ====================

  /// إضافة مهمة جديدة للمجموعة.
  Future<TaskModel> addTask({
    required String groupId,
    required String title,
    String? description,
    int points = 2,
    String iconId = 'mosque',
  }) async {
    try {
      // الحصول على عدد المهام الحالي
      final tasksQuery = await _groupsRef
          .doc(groupId)
          .collection('tasks')
          .get();

      if (tasksQuery.docs.length >= maxTasksPerGroup) {
        throw Exception('تم الوصول للحد الأقصى من المهام');
      }

      final docRef = _groupsRef.doc(groupId).collection('tasks').doc();
      final task = TaskModel.create(
        id: docRef.id,
        groupId: groupId,
        title: title,
        description: description,
        points: points,
        iconId: iconId,
        order: tasksQuery.docs.length,
      );

      await docRef.set(task.toJson());

      developer.log(
        'Task added: ${task.id} to group $groupId (points: $points)',
        name: 'sohba.task_repository',
      );

      return task;
    } catch (e) {
      developer.log(
        'Error adding task: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// تحديث مهمة.
  Future<void> updateTask(TaskModel task) async {
    try {
      await _groupsRef
          .doc(task.groupId)
          .collection('tasks')
          .doc(task.id)
          .update({
            'title': task.title,
            'description': task.description,
            'points': task.points,
            'icon_id': task.iconId,
            'order': task.order,
          });
    } catch (e) {
      developer.log(
        'Error updating task: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// حذف مهمة.
  Future<void> deleteTask(String groupId, String taskId) async {
    try {
      await _groupsRef.doc(groupId).collection('tasks').doc(taskId).delete();

      developer.log(
        'Task deleted: $taskId from group $groupId',
        name: 'sohba.task_repository',
      );
    } catch (e) {
      developer.log(
        'Error deleting task: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// الحصول على جميع مهام المجموعة.
  Future<List<TaskModel>> getTasks(String groupId) async {
    try {
      final query = await _groupsRef
          .doc(groupId)
          .collection('tasks')
          .orderBy('order')
          .get();

      return query.docs.map((doc) {
        return TaskModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      developer.log(
        'Error getting tasks: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      return [];
    }
  }

  /// Stream للاستماع لتحديثات المهام.
  Stream<List<TaskModel>> watchTasks(String groupId) {
    return _groupsRef
        .doc(groupId)
        .collection('tasks')
        .orderBy('order')
        .snapshots()
        .map((query) {
          return query.docs.map((doc) {
            return TaskModel.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  /// إعادة ترتيب المهام.
  Future<void> reorderTasks(String groupId, List<TaskModel> tasks) async {
    final batch = _firestore.batch();

    for (var i = 0; i < tasks.length; i++) {
      batch.update(
        _groupsRef.doc(groupId).collection('tasks').doc(tasks[i].id),
        {'order': i},
      );
    }

    await batch.commit();
  }

  // ==================== الإنجازات ====================

  /// تحديث حالة إنجاز مهمة وتحديث مجموع النقاط.
  Future<void> updateTaskCompletion({
    required String groupId,
    required String userId,
    required String taskId,
    required TaskStatus status,
    required int taskPoints,
  }) async {
    try {
      final dateKey = FajrTimeService.getCurrentDayKey();
      final completionRef = _groupsRef
          .doc(groupId)
          .collection('completions')
          .doc(dateKey)
          .collection('users')
          .doc(userId);

      final memberRef = _groupsRef
          .doc(groupId)
          .collection('members')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final completionDoc = await transaction.get(completionRef);
        String oldStatusVal = 'none';

        if (completionDoc.exists) {
          final data = completionDoc.data()!;
          final tasksMap = data['tasks'] as Map<String, dynamic>? ?? {};
          oldStatusVal = tasksMap[taskId] as String? ?? 'none';

          transaction.update(completionRef, {
            'tasks.$taskId': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          transaction.set(completionRef, {
            'user_id': userId,
            'date_key': dateKey,
            'tasks': {taskId: status.value},
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        final oldPoints = _calcPoints(oldStatusVal, taskPoints);
        final newPoints = _calcPoints(status.value, taskPoints);
        final pointsDelta = newPoints - oldPoints;

        if (pointsDelta != 0) {
          transaction.update(memberRef, {
            'total_points': FieldValue.increment(pointsDelta),
          });
        }
      });

      developer.log(
        'Task $taskId updated to ${status.value} for user $userId (points: $taskPoints)',
        name: 'sohba.task_repository',
      );
    } catch (e) {
      developer.log(
        'Error updating task completion: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      rethrow;
    }
  }

  int _calcPoints(String status, int maxPoints) {
    switch (status) {
      case 'complete':
        return maxPoints;
      case 'partial':
        return (maxPoints / 2).ceil();
      default:
        return 0;
    }
  }

  /// الحصول على إنجازات مستخدم لليوم.
  Future<TaskCompletionModel> getUserCompletions({
    required String groupId,
    required String userId,
    String? dateKey,
  }) async {
    try {
      final key = dateKey ?? FajrTimeService.getCurrentDayKey();
      final doc = await _groupsRef
          .doc(groupId)
          .collection('completions')
          .doc(key)
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return TaskCompletionModel.empty(userId: userId, dateKey: key);
      }

      return TaskCompletionModel.fromJson({...doc.data()!, 'user_id': doc.id});
    } catch (e) {
      developer.log(
        'Error getting user completions: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      return TaskCompletionModel.empty(
        userId: userId,
        dateKey: dateKey ?? FajrTimeService.getCurrentDayKey(),
      );
    }
  }

  /// الحصول على إنجازات جميع الأعضاء لليوم.
  Future<List<TaskCompletionModel>> getAllCompletions({
    required String groupId,
    String? dateKey,
  }) async {
    try {
      final key = dateKey ?? FajrTimeService.getCurrentDayKey();
      final query = await _groupsRef
          .doc(groupId)
          .collection('completions')
          .doc(key)
          .collection('users')
          .get();

      return query.docs.map((doc) {
        return TaskCompletionModel.fromJson({...doc.data(), 'user_id': doc.id});
      }).toList();
    } catch (e) {
      developer.log(
        'Error getting all completions: $e',
        name: 'sohba.task_repository',
        level: 900,
      );
      return [];
    }
  }

  /// Stream للاستماع لتحديثات إنجازات اليوم.
  Stream<List<TaskCompletionModel>> watchTodayCompletions(String groupId) {
    final dateKey = FajrTimeService.getCurrentDayKey();
    return _groupsRef
        .doc(groupId)
        .collection('completions')
        .doc(dateKey)
        .collection('users')
        .snapshots()
        .map((query) {
          return query.docs.map((doc) {
            return TaskCompletionModel.fromJson({
              ...doc.data(),
              'user_id': doc.id,
            });
          }).toList();
        });
  }

  /// Stream لإنجازات مستخدم محدد لليوم.
  Stream<TaskCompletionModel> watchUserCompletions({
    required String groupId,
    required String userId,
  }) {
    final dateKey = FajrTimeService.getCurrentDayKey();
    return _groupsRef
        .doc(groupId)
        .collection('completions')
        .doc(dateKey)
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return TaskCompletionModel.empty(userId: userId, dateKey: dateKey);
          }
          return TaskCompletionModel.fromJson({
            ...doc.data()!,
            'user_id': doc.id,
          });
        });
  }

  // ==================== Leaderboard ====================

  /// الحصول على ترتيب الأعضاء لليوم.
  Future<List<({String userId, int points})>> getLeaderboard({
    required String groupId,
    String? dateKey,
  }) async {
    final completions = await getAllCompletions(
      groupId: groupId,
      dateKey: dateKey,
    );

    final leaderboard = completions
        .map((c) => (userId: c.userId, points: c.totalPoints))
        .toList();

    // ترتيب تنازلي حسب النقاط
    leaderboard.sort((a, b) => b.points.compareTo(a.points));

    return leaderboard;
  }
}
