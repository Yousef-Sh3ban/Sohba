/// نموذج بيانات المهمة.
///
/// يمثل مهمة يومية في المجموعة.
class TaskModel {
  /// معرف المهمة الفريد.
  final String id;

  /// معرف المجموعة التي تنتمي إليها المهمة.
  final String groupId;

  /// عنوان المهمة.
  final String title;

  /// وصف المهمة (اختياري).
  final String? description;

  /// عدد النقاط للمهمة (يحددها الأدمن).
  final int points;

  /// معرف الأيقونة.
  final String iconId;

  /// ترتيب المهمة في القائمة.
  final int order;

  /// تاريخ إنشاء المهمة.
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    this.points = 2,
    this.iconId = 'mosque',
    required this.order,
    required this.createdAt,
  });

  /// إنشاء مهمة جديدة.
  factory TaskModel.create({
    required String id,
    required String groupId,
    required String title,
    String? description,
    int points = 2,
    String iconId = 'mosque',
    required int order,
  }) {
    return TaskModel(
      id: id,
      groupId: groupId,
      title: title,
      description: description,
      points: points,
      iconId: iconId,
      order: order,
      createdAt: DateTime.now(),
    );
  }

  //is this used ??
  /// إنشاء نموذج من خريطة JSON.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      points: json['points'] as int? ?? 2,
      iconId: json['icon_id'] as String? ?? 'mosque',
      order: json['order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  //is this used ??
  /// تحويل النموذج إلى خريطة JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'description': description,
      'points': points,
      'icon_id': iconId,
      'order': order,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// حساب النقاط حسب حالة الإنجاز.
  /// كامل = كل النقاط، بعضه = نصف النقاط (تقريب لأعلى).
  int getPointsForStatus(String status) {
    switch (status) {
      case 'complete':
        return points;
      case 'partial':
        return (points / 2).ceil();
      default:
        return 0;
    }
  }

  //is this used ??
  /// إنشاء نسخة معدلة من النموذج.
  TaskModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    int? points,
    String? iconId,
    int? order,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      iconId: iconId ?? this.iconId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  //is this used ??
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  //is this used ??
  @override
  int get hashCode => id.hashCode;

  //is this used ??
  @override
  String toString() => 'TaskModel(id: $id, title: $title, points: $points)';
}
