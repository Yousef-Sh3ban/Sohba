/// نموذج بيانات المجموعة.
///
/// يمثل مجموعة خاصة للتنافس على الطاعات.
class GroupModel {
  /// معرف المجموعة الفريد.
  final String id;

  /// اسم المجموعة.
  final String name;

  /// كود الدعوة للانضمام.
  final String inviteCode;

  /// معرف مدير المجموعة (الأدمن).
  final String adminId;

  /// تاريخ إنشاء المجموعة.
  final DateTime createdAt;

  /// عدد الأعضاء الحالي.
  final int memberCount;

  const GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.adminId,
    required this.createdAt,
    required this.memberCount,
  });

  /// إنشاء مجموعة جديدة.
  factory GroupModel.create({
    required String id,
    required String name,
    required String inviteCode,
    required String adminId,
  }) {
    return GroupModel(
      id: id,
      name: name,
      inviteCode: inviteCode,
      adminId: adminId,
      createdAt: DateTime.now(),
      memberCount: 0, // سيتم زيادته عند إضافة المنشئ كعضو
    );
  }

  /// إنشاء نموذج من خريطة JSON.
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      adminId: json['admin_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: json['member_count'] as int,
    );
  }

  /// تحويل النموذج إلى خريطة JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
    };
  }

  // is this used ??
  /// إنشاء نسخة معدلة من النموذج.
  GroupModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? adminId,
    DateTime? createdAt,
    int? memberCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  /// التحقق مما إذا كان المستخدم هو الأدمن.
  bool isAdmin(String userId) => adminId == userId;

  /// التحقق من إمكانية إضافة أعضاء جدد.
  bool get canAddMembers => memberCount < 50;

  // is this uesd ??
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  // is this uesd ??
  @override
  int get hashCode => id.hashCode;

  // is this uesd ??
  @override
  String toString() => 'GroupModel(id: $id, name: $name)';
}
