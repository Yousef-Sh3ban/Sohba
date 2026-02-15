import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

/// حوار التحديث - يظهر عند توفر نسخة جديدة.
///
/// يدعم نوعين:
/// 1. تحديث اختياري - يمكن إغلاقه والمتابعة
/// 2. تحديث إجباري - يجب التحديث للمتابعة
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // منع الإغلاق إذا كان التحديث إجبارياً
      canPop: !updateInfo.isForceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: updateInfo.isForceUpdate
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                updateInfo.isForceUpdate
                    ? Icons.error_outline_rounded
                    : Icons.system_update_rounded,
                color: updateInfo.isForceUpdate ? Colors.red : Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                updateInfo.isForceUpdate ? 'تحديث مطلوب' : 'تحديث متاح',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              updateInfo.message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            if (updateInfo.isForceUpdate) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لا يمكن استخدام التطبيق بدون التحديث',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // زر "لاحقاً" - يظهر فقط للتحديثات الاختيارية
          if (!updateInfo.isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('لاحقاً'),
            ),
          // زر "تحديث"
          ElevatedButton(
            onPressed: () => _launchUpdate(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: updateInfo.isForceUpdate
                  ? Colors.red
                  : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.download_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'تحديث الآن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// فتح رابط التحديث في المتصفح.
  Future<void> _launchUpdate(BuildContext context) async {
    if (updateInfo.updateUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('رابط التحديث غير متوفر')));
      }
      return;
    }

    try {
      final uri = Uri.parse(updateInfo.updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // إغلاق الحوار بعد فتح الرابط (للتحديثات الاختيارية فقط)
        if (context.mounted && !updateInfo.isForceUpdate) {
          Navigator.of(context).pop();
        }
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل فتح رابط التحديث: $e',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    }
  }

  /// عرض حوار التحديث.
  static Future<void> show(BuildContext context, UpdateInfo updateInfo) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }
}
