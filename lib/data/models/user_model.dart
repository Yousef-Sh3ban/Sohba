/// نموذج بيانات المستخدم.
///
/// يمثل مستخدم التطبيق المعرّف بمعرف الجهاز الفريد.
class UserModel {
  /// معرف المستخدم الفريد (Device ID).
  final String id;

  /// اسم المستخدم المعروض.
  final String name;

  /// تاريخ إنشاء الحساب.
  final DateTime createdAt;

  /// تاريخ آخر نشاط.
  final DateTime lastActiveAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastActiveAt,
  });

  /// إنشاء مستخدم جديد.
  factory UserModel.create({required String id, required String name}) {
    final now = DateTime.now();
    return UserModel(id: id, name: name, createdAt: now, lastActiveAt: now);
  }

  /// إنشاء نموذج من خريطة JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
    );
  }

  /// تحويل النموذج إلى خريطة JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  /// إنشاء نسخة معدلة من النموذج.
  UserModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, name: $name)';
}
