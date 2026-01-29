import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/device_id_service.dart';
import '../../../../data/models/user_model.dart';

/// شاشة الترحيب وإدخال الاسم.
///
/// تظهر للمستخدمين الجدد لإدخال اسمهم المعروض.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await DeviceIdService.getDeviceId();
      final userName = _nameController.text.trim();

      // حفظ الاسم ومعرف الجهاز محلياً
      await prefs.setString(userNameKey, userName);
      await prefs.setString(deviceIdKey, deviceId);

      // حفظ المستخدم في Firestore
      final user = UserModel.create(id: deviceId, name: userName);
      await AppServices.instance.userRepository.saveUser(user);

      developer.log(
        'User registered: $userName (ID: $deviceId)',
        name: 'sohba.welcome',
      );

      // تحديث حالة المصادقة للانتقال للصفحة التالية تلقائياً
      AppServices.instance.authState.value = true;
      // لا حاجة لاستخدام context.go لأن Router سيقوم بالتحويل تلقائياً عند تغيير authState
    } catch (e) {
      developer.log('Error saving user: $e', name: 'sohba.welcome', level: 900);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الأيقونة
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: 60,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // العنوان
                Text(
                  'صحبة',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // الوصف
                Text(
                  'تنافسوا على الخير مع أصحابكم',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // نموذج إدخال الاسم
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('ما اسمك؟', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'أدخل اسمك هنا',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال اسمك';
                          }
                          if (value.trim().length < 2) {
                            return 'الاسم قصير جداً';
                          }
                          if (value.trim().length > 30) {
                            return 'الاسم طويل جداً';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _saveAndContinue(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _saveAndContinue,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : SizedBox(),
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('ابدأ'),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ملاحظة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'هذا الاسم سيظهر لأصدقائك في المجموعات',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
