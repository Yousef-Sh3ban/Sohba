import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تهيئة الخدمات
  AppServices.instance.initialize();

  // التحقق من حالة المستخدم
  final prefs = await SharedPreferences.getInstance();
  final hasUserName = prefs.getString(userNameKey) != null;
  final hasGroups = prefs.getString(lastGroupIdKey) != null;

  runApp(SohbaApp(hasUserName: hasUserName, hasGroups: hasGroups));
}
