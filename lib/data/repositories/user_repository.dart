import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// Repository للتعامل مع بيانات المستخدمين في Firestore.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// مرجع collection المستخدمين.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// إنشاء أو تحديث مستخدم.
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersRef.doc(user.id).set(user.toJson(), SetOptions(merge: true));
      developer.log('User saved: ${user.id}', name: 'sohba.user_repository');
    } catch (e) {
      developer.log(
        'Error saving user: $e',
        name: 'sohba.user_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// الحصول على مستخدم بواسطة المعرف.
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      developer.log(
        'Error getting user: $e',
        name: 'sohba.user_repository',
        level: 900,
      );
      rethrow;
    }
  }

  /// تحديث آخر نشاط للمستخدم.
  Future<void> updateLastActive(String userId) async {
    try {
      await _usersRef.doc(userId).update({
        'last_active_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log(
        'Error updating last active: $e',
        name: 'sohba.user_repository',
        level: 900,
      );
    }
  }

  /// تحديث اسم المستخدم.
  Future<void> updateUserName(String userId, String newName) async {
    try {
      await _usersRef.doc(userId).update({'name': newName});
    } catch (e) {
      developer.log(
        'Error updating user name: $e',
        name: 'sohba.user_repository',
        level: 900,
      );
      rethrow;
    }
  }
}
