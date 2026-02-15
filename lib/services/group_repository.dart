import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_constants.dart';
import 'invite_code_generator.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';

/// Repository للتعامل مع بيانات المجموعات في Firestore.
class GroupRepository {
  GroupRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// مرجع collection المجموعات.
  CollectionReference<Map<String, dynamic>> get _groupsRef =>
      _firestore.collection('groups');

  /// إنشاء مجموعة جديدة.
  Future<GroupModel> createGroup({
    required String name,
    required String adminId,
    required String adminName,
  }) async {
    try {
      // إنشاء كود دعوة فريد
      String inviteCode;
      bool isUnique = false;
      do {
        inviteCode = InviteCodeGenerator.generate();
        final existing = await getGroupByInviteCode(inviteCode);
        isUnique = existing == null;
      } while (!isUnique);

      // إنشاء المجموعة
      final docRef = _groupsRef.doc();
      final group = GroupModel.create(
        id: docRef.id,
        name: name,
        inviteCode: inviteCode,
        adminId: adminId,
      );

      await docRef.set(group.toJson());

      // إضافة المنشئ كعضو
      await addMember(groupId: docRef.id, userId: adminId, userName: adminName);

      developer.log(
        'Group created: ${group.id} with code: $inviteCode',
        name: 'sohba.group_repository',
      );

      return group;
    } catch (e) {
      developer.log(
        'Error creating group: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// الحصول على مجموعة بواسطة المعرف.
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _groupsRef.doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      developer.log(
        'Error getting group: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// الحصول على مجموعة بواسطة كود الدعوة.
  Future<GroupModel?> getGroupByInviteCode(String inviteCode) async {
    try {
      final query = await _groupsRef
          .where('invite_code', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      return GroupModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      developer.log(
        'Error getting group by invite code: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// الانضمام لمجموعة بكود الدعوة.
  Future<GroupModel?> joinGroup({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    try {
      final group = await getGroupByInviteCode(inviteCode);
      if (group == null) return null;

      // التحقق من الحد الأقصى للأعضاء
      if (group.memberCount >= maxMembersPerGroup) {
        throw Exception('المجموعة ممتلئة');
      }

      // التحقق من عدم الانضمام مسبقاً
      final existingMember = await getMember(group.id, userId);
      if (existingMember != null) {
        return group; // المستخدم عضو بالفعل
      }

      // إضافة العضو
      await addMember(groupId: group.id, userId: userId, userName: userName);

      developer.log(
        'User $userId joined group ${group.id}',
        name: 'sohba.group_repository',
      );

      return group;
    } catch (e) {
      developer.log(
        'Error joining group: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// إضافة عضو للمجموعة.
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String userName,
  }) async {
    final member = GroupMemberModel.create(userId: userId, userName: userName);

    final batch = _firestore.batch();

    // إضافة العضو
    batch.set(
      _groupsRef.doc(groupId).collection('members').doc(userId),
      member.toJson(),
    );

    // زيادة عدد الأعضاء
    batch.update(_groupsRef.doc(groupId), {
      'member_count': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// الحصول على عضو في مجموعة.
  Future<GroupMemberModel?> getMember(String groupId, String userId) async {
    try {
      final doc = await _groupsRef
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return GroupMemberModel.fromJson({...doc.data()!, 'user_id': doc.id});
    } catch (e) {
      return null;
    }
  }

  /// الحصول على جميع أعضاء المجموعة.
  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    try {
      final query = await _groupsRef.doc(groupId).collection('members').get();

      return query.docs.map((doc) {
        return GroupMemberModel.fromJson({...doc.data(), 'user_id': doc.id});
      }).toList();
    } catch (e) {
      developer.log(
        'Error getting members: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      return [];
    }
  }

  /// تحديث الـ Streak للعضو.
  /// يُستدعى عند تحقيق 50%+ من النقاط في اليوم.
  Future<void> updateStreak({
    required String groupId,
    required String userId,
    required String todayKey,
    required bool achieved50Percent,
  }) async {
    try {
      final memberRef = _groupsRef
          .doc(groupId)
          .collection('members')
          .doc(userId);
      final memberDoc = await memberRef.get();

      if (!memberDoc.exists) return;

      final data = memberDoc.data()!;
      final currentStreak = data['current_streak'] as int? ?? 0;
      final longestStreak = data['longest_streak'] as int? ?? 0;
      final lastStreakDate = data['last_streak_date'] as String?;

      // حساب تاريخ الأمس
      final today = DateTime.parse('${todayKey}T00:00:00');
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      int newStreak;

      if (achieved50Percent) {
        // تم تحقيق الهدف اليوم
        if (lastStreakDate == todayKey) {
          // تم التحديث اليوم بالفعل، لا تغيير
          return;
        } else if (lastStreakDate == yesterdayKey) {
          // استمرار السلسلة
          newStreak = currentStreak + 1;
        } else {
          // بداية سلسلة جديدة
          newStreak = 1;
        }

        final newLongest = newStreak > longestStreak
            ? newStreak
            : longestStreak;

        await memberRef.update({
          'current_streak': newStreak,
          'longest_streak': newLongest,
          'last_streak_date': todayKey,
        });

        developer.log(
          'Streak updated for $userId: $newStreak (longest: $newLongest)',
          name: 'sohba.group_repository',
        );
      }
      // ملاحظة: لا نقوم بإعادة تعيين الـ streak هنا
      // سيتم ذلك تلقائياً عند تحقيق 50% في يوم جديد
    } catch (e) {
      developer.log(
        'Error updating streak: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
    }
  }

  /// الحصول على مجموعات المستخدم.
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      // البحث في جميع المجموعات التي المستخدم عضو فيها
      final groupsQuery = await _firestore
          .collectionGroup('members')
          .where('user_id', isEqualTo: userId)
          .get();

      final groups = <GroupModel>[];
      for (final memberDoc in groupsQuery.docs) {
        // استخراج معرف المجموعة من المسار
        final groupId = memberDoc.reference.parent.parent?.id;
        if (groupId != null) {
          final group = await getGroup(groupId);
          if (group != null) {
            groups.add(group);
          }
        }
      }

      return groups;
    } catch (e) {
      developer.log(
        'Error getting user groups: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      return [];
    }
  }

  /// Stream للاستماع لتحديثات المجموعة.
  Stream<GroupModel?> watchGroup(String groupId) {
    return _groupsRef.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  /// Stream للاستماع لتحديثات أعضاء المجموعة.
  Stream<List<GroupMemberModel>> watchMembers(String groupId) {
    return _groupsRef.doc(groupId).collection('members').snapshots().map((
      query,
    ) {
      return query.docs.map((doc) {
        return GroupMemberModel.fromJson({...doc.data(), 'user_id': doc.id});
      }).toList();
    });
  }

  /// تحديث اسم المجموعة.
  Future<void> updateGroupName(String groupId, String newName) async {
    await _groupsRef.doc(groupId).update({'name': newName});
  }

  /// نقل صلاحية الأدمن.
  Future<void> transferAdmin(String groupId, String newAdminId) async {
    await _groupsRef.doc(groupId).update({'admin_id': newAdminId});
  }

  /// مغادرة المجموعة.
  /// إذا أصبحت المجموعة فارغة بعد المغادرة، يتم حذفها.
  Future<void> leaveGroup(String groupId, String userId) async {
    // أولاً: الحصول على عدد الأعضاء الحالي
    final group = await getGroup(groupId);
    if (group == null) return;

    // حذف العضوية
    await _groupsRef.doc(groupId).collection('members').doc(userId).delete();

    // إذا كان آخر عضو، احذف المجموعة بالكامل
    if (group.memberCount <= 1) {
      await deleteGroup(groupId);
      developer.log(
        'Group $groupId deleted (empty)',
        name: 'sohba.group_repository',
      );
    } else {
      // تقليل عدد الأعضاء
      await _groupsRef.doc(groupId).update({
        'member_count': FieldValue.increment(-1),
      });
    }
  }

  /// طرد عضو من المجموعة (للأدمن فقط).
  Future<void> kickMember(String groupId, String memberId) async {
    await leaveGroup(groupId, memberId);
  }

  /// حذف المجموعة وجميع بياناتها.
  Future<void> deleteGroup(String groupId) async {
    final batch = _firestore.batch();

    // 1. حذف جميع الأعضاء
    final membersSnapshot = await _groupsRef
        .doc(groupId)
        .collection('members')
        .get();
    for (final doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. حذف جميع المهام
    final tasksSnapshot = await _groupsRef
        .doc(groupId)
        .collection('tasks')
        .get();
    for (final doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 3. حذف سجلات الإتمام (completions/users/*)
    final completionsSnapshot = await _groupsRef
        .doc(groupId)
        .collection('completions')
        .get();
    for (final completionDoc in completionsSnapshot.docs) {
      // حذف users داخل كل completion
      final usersSnapshot = await completionDoc.reference
          .collection('users')
          .get();
      for (final userDoc in usersSnapshot.docs) {
        batch.delete(userDoc.reference);
      }
      batch.delete(completionDoc.reference);
    }

    // 4. حذف document المجموعة نفسها
    batch.delete(_groupsRef.doc(groupId));

    await batch.commit();

    developer.log(
      'Group $groupId and all subcollections deleted',
      name: 'sohba.group_repository',
    );
  }

  /// تحديث اسم العضو في جميع المجموعات.
  /// يُستدعى عند تغيير الاسم من الإعدادات.
  Future<void> updateMemberNameInAllGroups({
    required String userId,
    required String newName,
  }) async {
    try {
      // البحث في جميع المجموعات التي المستخدم عضو فيها
      final memberDocs = await _firestore
          .collectionGroup('members')
          .where('user_id', isEqualTo: userId)
          .get();

      if (memberDocs.docs.isEmpty) {
        developer.log(
          'No group memberships found for user $userId',
          name: 'sohba.group_repository',
        );
        return;
      }

      final batch = _firestore.batch();

      for (final doc in memberDocs.docs) {
        batch.update(doc.reference, {'user_name': newName});
      }

      await batch.commit();

      developer.log(
        'Updated name to "$newName" in ${memberDocs.docs.length} groups',
        name: 'sohba.group_repository',
      );
    } catch (e) {
      developer.log(
        'Error updating member name in all groups: $e',
        name: 'sohba.group_repository',
        level: 900,
      );
      rethrow;
    }
  }
}
