import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/app_constants.dart';
import 'services/app_services.dart';
import 'services/connectivity_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✨ تفعيل Firebase Offline Persistence (مهم جداً!)
  // هذا يضمن حفظ التغييرات محلياً وإرسالها تلقائياً عند عودة الإنترنت
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // تفعيل التخزين المحلي
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // حجم الكاش غير محدود
  );

  // تهيئة خدمة مراقبة الاتصال
  await ConnectivityService.instance.initialize();

  // تهيئة الخدمات
  AppServices.instance.initialize();

  // التحقق من حالة المستخدم
  final prefs = await SharedPreferences.getInstance();
  final hasUserName = prefs.getString(userNameKey) != null;
  final hasGroups = prefs.getString(lastGroupIdKey) != null;

  // تحديث حالة المصادقة
  AppServices.instance.authState.value = hasUserName;

  runApp(SohbaApp(hasUserName: hasUserName, hasGroups: hasGroups));
}
