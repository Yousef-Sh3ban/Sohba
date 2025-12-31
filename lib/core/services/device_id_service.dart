import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// خدمة إدارة معرف الجهاز الفريد.
///
/// تستخدم لتعريف المستخدم بشكل فريد بدون تسجيل دخول.
class DeviceIdService {
  DeviceIdService._();

  static String? _cachedDeviceId;

  /// الحصول على معرف الجهاز الفريد.
  ///
  /// يحاول أولاً استرجاع المعرف المخزن محلياً.
  /// إذا لم يوجد، يتم إنشاء معرف جديد من معلومات الجهاز.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(deviceIdKey);

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await prefs.setString(deviceIdKey, deviceId);
      developer.log(
        'Generated new device ID: $deviceId',
        name: 'sohba.device_id',
      );
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// إنشاء معرف جهاز فريد من معلومات الجهاز.
  static Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      final androidInfo = await deviceInfo.androidInfo;
      // استخدام Android ID كمعرف أساسي
      final androidId = androidInfo.id;
      final model = androidInfo.model;
      final brand = androidInfo.brand;

      // دمج المعلومات لإنشاء معرف فريد
      final combined = '$androidId-$brand-$model';
      return combined.hashCode.toRadixString(36);
    } catch (e) {
      developer.log(
        'Error getting device info: $e',
        name: 'sohba.device_id',
        level: 900,
      );
      // في حالة الفشل، إنشاء معرف عشوائي
      return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    }
  }

  /// مسح معرف الجهاز المخزن (للاختبار فقط).
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(deviceIdKey);
    _cachedDeviceId = null;
  }
}
