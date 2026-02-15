import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// خدمة التحقق من التحديثات باستخدام Firebase Remote Config.
///
/// تتحقق من وجود نسخة جديدة وتحدد ما إذا كان التحديث إجبارياً أو اختيارياً.
class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// تهيئة Remote Config.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // إعدادات Remote Config
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1), // تحديث فوري في الـ Debug
        ),
      );

      // القيم الافتراضية
      await _remoteConfig.setDefaults({
        'latest_version': '1.0.0', // آخر نسخة متاحة
        'min_supported_version': '1.0.0', // أقل نسخة مدعومة
        'update_url': '', // رابط تحميل APK
        'update_message': 'يتوفر تحديث جديد لتطبيق صُحبة',
        'force_update_message':
            'هذه النسخة لم تعد مدعومة. يرجى التحديث للمتابعة.',
      });

      // جلب القيم من السيرفر
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      developer.log('UpdateService initialized', name: 'sohba.update');
    } catch (e) {
      developer.log(
        'Error initializing UpdateService: $e',
        name: 'sohba.update',
        level: 900,
      );
    }
  }

  /// التحقق من وجود تحديث.
  ///
  /// يُرجع: (hasUpdate, isForceUpdate, updateUrl, message)
  Future<UpdateInfo> checkForUpdate() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // الحصول على النسخة الحالية للتطبيق
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // الحصول على القيم من Remote Config
      final latestVersion = _remoteConfig.getString('latest_version');
      final minSupportedVersion = _remoteConfig.getString(
        'min_supported_version',
      );
      final updateUrl = _remoteConfig.getString('update_url');
      final updateMessage = _remoteConfig.getString('update_message');
      final forceUpdateMessage = _remoteConfig.getString(
        'force_update_message',
      );

      developer.log(
        'Version check: current=$currentVersion, latest=$latestVersion, min=$minSupportedVersion',
        name: 'sohba.update',
      );

      // التحقق من الإجبارية (النسخة الحالية أقل من الحد الأدنى المدعوم)
      if (_compareVersions(currentVersion, minSupportedVersion) < 0) {
        return UpdateInfo(
          hasUpdate: true,
          isForceUpdate: true,
          updateUrl: updateUrl,
          message: forceUpdateMessage,
        );
      }

      // التحقق من توفر تحديث اختياري
      if (_compareVersions(currentVersion, latestVersion) < 0) {
        return UpdateInfo(
          hasUpdate: true,
          isForceUpdate: false,
          updateUrl: updateUrl,
          message: updateMessage,
        );
      }

      // لا يوجد تحديث
      return UpdateInfo(
        hasUpdate: false,
        isForceUpdate: false,
        updateUrl: '',
        message: '',
      );
    } catch (e) {
      developer.log(
        'Error checking for update: $e',
        name: 'sohba.update',
        level: 900,
      );
      return UpdateInfo(
        hasUpdate: false,
        isForceUpdate: false,
        updateUrl: '',
        message: '',
      );
    }
  }

  /// مقارنة نسختين (مثل: "1.2.3" و "1.3.0").
  ///
  /// يُرجع:
  /// - سالب إذا كانت v1 < v2
  /// - صفر إذا كانت v1 == v2
  /// - موجب إذا كانت v1 > v2
  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.tryParse).toList();
    final v2Parts = v2.split('.').map(int.tryParse).toList();

    final maxLength = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final num1 = i < v1Parts.length ? (v1Parts[i] ?? 0) : 0;
      final num2 = i < v2Parts.length ? (v2Parts[i] ?? 0) : 0;

      if (num1 != num2) {
        return num1.compareTo(num2);
      }
    }

    return 0;
  }
}

/// معلومات التحديث.
class UpdateInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String updateUrl;
  final String message;

  UpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.updateUrl,
    required this.message,
  });
}
