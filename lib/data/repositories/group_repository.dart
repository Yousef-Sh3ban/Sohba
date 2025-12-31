import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/invite_code_generator.dart';
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
  Future<void> leaveGroup(String groupId, String userId) async {
    final batch = _firestore.batch();

    // حذف العضوية
    batch.delete(_groupsRef.doc(groupId).collection('members').doc(userId));

    // تقليل عدد الأعضاء
    batch.update(_groupsRef.doc(groupId), {
      'member_count': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// طرد عضو من المجموعة (للأدمن فقط).
  Future<void> kickMember(String groupId, String memberId) async {
    await leaveGroup(groupId, memberId);
  }

  /// حذف المجموعة.
  Future<void> deleteGroup(String groupId) async {
    // حذف جميع الأعضاء أولاً
    final members = await getMembers(groupId);
    final batch = _firestore.batch();

    for (final member in members) {
      batch.delete(
        _groupsRef.doc(groupId).collection('members').doc(member.userId),
      );
    }

    // حذف المجموعة
    batch.delete(_groupsRef.doc(groupId));

    await batch.commit();
  }
}
