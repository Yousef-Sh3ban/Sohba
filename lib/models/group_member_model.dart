/// نموذج بيانات عضو المجموعة.
///
/// يمثل عضوية مستخدم في مجموعة معينة.
class GroupMemberModel {
  /// معرف المستخدم.
  final String userId;

  /// اسم المستخدم المعروض.
  final String userName;

  /// تاريخ الانضمام للمجموعة.
  final DateTime joinedAt;

  /// عدد أيام الـ Streak الحالية.
  final int currentStreak;

  /// أطول Streak حققها العضو.
  final int longestStreak;

  /// آخر يوم تم فيه تحديث الـ streak (بصيغة YYYY-MM-DD).
  final String? lastStreakDate;

  /// إجمالي النقاط على مدار كل الأيام.
  final int totalPoints;

  const GroupMemberModel({
    required this.userId,
    required this.userName,
    required this.joinedAt,
    required this.currentStreak,
    required this.longestStreak,
    this.lastStreakDate,
    this.totalPoints = 0,
  });

  /// إنشاء عضوية جديدة.
  factory GroupMemberModel.create({
    required String userId,
    required String userName,
  }) {
    return GroupMemberModel(
      userId: userId,
      userName: userName,
      joinedAt: DateTime.now(),
      currentStreak: 0,
      longestStreak: 0,
    );
  }

  /// إنشاء نموذج من خريطة JSON.
  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastStreakDate: json['last_streak_date'] as String?,
      totalPoints: json['total_points'] as int? ?? 0,
    );
  }

  /// تحويل النموذج إلى خريطة JSON.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'joined_at': joinedAt.toIso8601String(),
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_streak_date': lastStreakDate,
      'total_points': totalPoints,
    };
  }

  /// إنشاء نسخة معدلة من النموذج.
  GroupMemberModel copyWith({
    String? userId,
    String? userName,
    DateTime? joinedAt,
    int? currentStreak,
    int? longestStreak,
    String? lastStreakDate,
    int? totalPoints,
  }) {
    return GroupMemberModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      joinedAt: joinedAt ?? this.joinedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMemberModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'GroupMemberModel(userId: $userId, name: $userName)';
}
