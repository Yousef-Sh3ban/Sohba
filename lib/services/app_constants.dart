/// ثوابت التطبيق العامة.
///
/// يحتوي على جميع الحدود والقيم الثابتة المستخدمة في التطبيق.
library;

/// الحد الأقصى لعدد الأعضاء في المجموعة الواحدة.
const int maxMembersPerGroup = 50;

/// الحد الأقصى لعدد المجموعات التي يمكن للمستخدم الانضمام إليها.
const int maxGroupsPerUser = 3;

/// الحد الأقصى لعدد المهام في المجموعة الواحدة.
const int maxTasksPerGroup = 20;

/// مدة الاحتفاظ بالسجلات بالأيام (سنة واحدة).
const int historyRetentionDays = 365;

/// طول كود الدعوة.
const int inviteCodeLength = 6;

/// مفتاح حفظ معرف الجهاز.
const String deviceIdKey = 'device_id';

/// مفتاح حفظ اسم المستخدم.
const String userNameKey = 'user_name';

/// مفتاح حفظ آخر مجموعة تم فتحها.
const String lastGroupIdKey = 'last_group_id';

/// مفتاح حفظ قائمة معرفات مجموعات المستخدم.
const String userGroupIdsKey = 'user_group_ids';

/// مفتاح حفظ إعدادات الثيم.
const String themeModeKey = 'theme_mode';

/// مفتاح حفظ إعدادات الإشعارات.
const String notificationsEnabledKey = 'notifications_enabled';
