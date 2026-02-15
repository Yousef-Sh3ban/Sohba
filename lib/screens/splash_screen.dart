// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                           SPLASH SCREEN                                    ║
// ║  شاشة البداية مع gradient وانيميشن للوجو                                    ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../services/app_constants.dart';
import '../services/app_services.dart';
import '../services/device_id_service.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

/// شاشة البداية مع gradient background و animated logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  /// تهيئة التطبيق والتحقق من المستخدم الموجود.
  Future<void> _initializeAndNavigate() async {
    // انتظار الحد الأدنى لعرض الـ Splash
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // ✨ التحقق من التحديثات أولاً
    await _checkForUpdates();

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLocalUserName = prefs.getString(userNameKey) != null;

      developer.log(
        'Local username exists: $hasLocalUserName',
        name: 'sohba.splash',
      );

      // إذا كان الاسم موجود محلياً، انتقل مباشرة
      if (hasLocalUserName) {
        _navigateToApp();
        return;
      }

      // التحقق من وجود المستخدم في Firebase بناءً على Hardware Device ID
      // نستخدم getHardwareDeviceId لأن SharedPreferences تُمسح عند حذف التطبيق
      final deviceId = await DeviceIdService.getHardwareDeviceId();

      developer.log('Hardware Device ID: $deviceId', name: 'sohba.splash');

      final existingUser = await AppServices.instance.userRepository.getUser(
        deviceId,
      );

      developer.log(
        'Existing user from Firebase: ${existingUser?.name ?? "NOT FOUND"}',
        name: 'sohba.splash',
      );

      if (existingUser != null) {
        // المستخدم موجود في Firebase - استعادة الجلسة
        developer.log(
          'Existing user found: ${existingUser.name} (ID: $deviceId)',
          name: 'sohba.splash',
        );

        // حفظ البيانات محلياً
        await prefs.setString(userNameKey, existingUser.name);
        await prefs.setString(deviceIdKey, deviceId);

        // تحديث آخر نشاط
        await AppServices.instance.userRepository.updateLastActive(deviceId);

        // تحديث حالة المصادقة
        AppServices.instance.authState.value = true;

        _navigateToApp();
      } else {
        // مستخدم جديد - الذهاب لشاشة الترحيب
        developer.log(
          'New user detected, navigating to welcome',
          name: 'sohba.splash',
        );
        _navigateToWelcome();
      }
    } catch (e) {
      developer.log(
        'Error during initialization: $e',
        name: 'sohba.splash',
        level: 900,
      );
      // في حالة الخطأ، الذهاب لشاشة الترحيب
      _navigateToWelcome();
    }
  }

  /// التحقق من وجود تحديثات جديدة.
  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateService.instance.checkForUpdate();

      if (updateInfo.hasUpdate && mounted) {
        // عرض حوار التحديث
        await UpdateDialog.show(context, updateInfo);
      }
    } catch (e) {
      developer.log(
        'Error checking for updates: $e',
        name: 'sohba.splash',
        level: 900,
      );
      // الاستمرار حتى لو فشل التحقق من التحديثات
    }
  }

  void _navigateToApp() {
    if (mounted) {
      context.go('/my-tasks');
    }
  }

  void _navigateToWelcome() {
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryLight,
              AppTheme.primaryDark,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child:
              SvgPicture.asset(
                    'assets/icons/logo.svg',
                    width: 200,
                    height: 200,
                    colorFilter: ColorFilter.mode(
                      AppTheme.mainGold,
                      BlendMode.srcIn,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  )
                  .then(delay: 800.ms)
                  .shimmer(
                    duration: 1200.ms,
                    color: AppTheme.accentLight.withValues(alpha: 0.3),
                  ),
        ),
      ),
    );
  }
}
