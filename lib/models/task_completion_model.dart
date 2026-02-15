/// حالة إنجاز المهمة.
enum TaskStatus {
  /// لم يتم البدء في المهمة.
  none,

  /// تم إنجاز جزء من المهمة.
  partial,

  /// تم إنجاز المهمة بالكامل.
  complete;

  /// الحصول على القيمة النصية.
  String get value {
    switch (this) {
      case TaskStatus.none:
        return 'none';
      case TaskStatus.partial:
        return 'partial';
      case TaskStatus.complete:
        return 'complete';
    }
  }

  /// إنشاء من قيمة نصية.
  static TaskStatus fromString(String value) {
    switch (value) {
      case 'partial':
        return TaskStatus.partial;
      case 'complete':
        return TaskStatus.complete;
      default:
        return TaskStatus.none;
    }
  }

  /// الحصول على النص العربي للعرض.
  String get displayText {
    switch (this) {
      case TaskStatus.none:
        return 'لم أبدأ';
      case TaskStatus.partial:
        return 'بعضه';
      case TaskStatus.complete:
        return 'كامل';
    }
  }

  /// الحصول على الأيقونة المناسبة.
  String get icon {
    switch (this) {
      case TaskStatus.none:
        return '○';
      case TaskStatus.partial:
        return '◐';
      case TaskStatus.complete:
        return '●';
    }
  }

  /// الحصول على النقاط للـ Leaderboard.
  int get points {
    switch (this) {
      case TaskStatus.none:
        return 0;
      case TaskStatus.partial:
        return 1;
      case TaskStatus.complete:
        return 2;
    }
  }
}

/// نموذج إنجازات المهام لمستخدم في يوم معين.
///
/// يمثل حالة إنجاز جميع مهام اليوم لمستخدم واحد.
class TaskCompletionModel {
  /// معرف المستخدم.
  final String userId;

  /// مفتاح اليوم (YYYY-MM-DD).
  final String dateKey;

  /// خريطة حالة كل مهمة.
  /// المفتاح: معرف المهمة، القيمة: حالة الإنجاز.
  final Map<String, TaskStatus> tasks;

  /// وقت آخر تحديث.
  final DateTime? updatedAt;

  const TaskCompletionModel({
    required this.userId,
    required this.dateKey,
    required this.tasks,
    this.updatedAt,
  });

  /// إنشاء سجل إنجازات فارغ.
  factory TaskCompletionModel.empty({
    required String userId,
    required String dateKey,
  }) {
    return TaskCompletionModel(
      userId: userId,
      dateKey: dateKey,
      tasks: {},
      updatedAt: null,
    );
  }

  /// إنشاء نموذج من خريطة JSON.
  factory TaskCompletionModel.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as Map<String, dynamic>? ?? {};
    final tasks = tasksJson.map(
      (key, value) => MapEntry(key, TaskStatus.fromString(value as String)),
    );

    return TaskCompletionModel(
      userId: json['user_id'] as String,
      dateKey: json['date_key'] as String,
      tasks: tasks,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// تحويل النموذج إلى خريطة JSON.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date_key': dateKey,
      'tasks': tasks.map((key, value) => MapEntry(key, value.value)),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// الحصول على حالة مهمة معينة.
  TaskStatus getTaskStatus(String taskId) {
    return tasks[taskId] ?? TaskStatus.none;
  }

  /// إنشاء نسخة مع تحديث حالة مهمة.
  TaskCompletionModel updateTask(String taskId, TaskStatus status) {
    return TaskCompletionModel(
      userId: userId,
      dateKey: dateKey,
      tasks: {...tasks, taskId: status},
      updatedAt: DateTime.now(),
    );
  }

  /// حساب إجمالي النقاط.
  int get totalPoints {
    return tasks.values.fold(0, (sum, status) => sum + status.points);
  }

  /// حساب نسبة الإنجاز.
  double getCompletionPercentage(int totalTasks) {
    if (totalTasks == 0) return 0;
    final maxPoints = totalTasks * 2; // 2 نقاط لكل مهمة كاملة
    return (totalPoints / maxPoints) * 100;
  }

  /// التحقق من إنجاز جميع المهام بالكامل.
  bool isFullyCompleted(List<String> taskIds) {
    return taskIds.every((id) => tasks[id] == TaskStatus.complete);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskCompletionModel &&
        other.userId == userId &&
        other.dateKey == dateKey;
  }

  @override
  int get hashCode => Object.hash(userId, dateKey);

  @override
  String toString() =>
      'TaskCompletionModel(userId: $userId, date: $dateKey, tasks: ${tasks.length})';
}
