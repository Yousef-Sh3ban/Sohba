// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                         GROUP INFO SHEET                                   ║
// ║  عرض معلومات المجموعة وكود الدعوة - بتصميم أنيق                            ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_theme.dart';
import '../models/group_model.dart';
import '../widgets/animated_bottom_sheet.dart';

/// Bottom Sheet لعرض معلومات المجموعة وكود الدعوة
class GroupInfoSheet extends StatelessWidget {
  final GroupModel group;

  const GroupInfoSheet({required this.group, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // المقبض
            // ═══════════════════════════════════════════════════════════════
            const SheetHandle(),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // العنوان
            // ═══════════════════════════════════════════════════════════════
            const SheetHeader(
              icon: Icons.info_outline_rounded,
              title: 'معلومات المجموعة',
              subtitle: 'شارك كود الدعوة مع أصدقائك',
              delay: Duration(milliseconds: 100),
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // معلومات المجموعة
            // ═══════════════════════════════════════════════════════════════
            _buildInfoSection(theme, isDark)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 450.ms,
                  curve: Curves.easeOutQuart,
                ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // كود الدعوة
            // ═══════════════════════════════════════════════════════════════
            _buildInviteCodeSection(context, theme, isDark)
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 450.ms,
                  curve: Curves.easeOutQuart,
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // اسم المجموعة
          _buildInfoRow(
            icon: Icons.group_rounded,
            label: 'اسم المجموعة',
            value: group.name,
            theme: theme,
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),

          // عدد الأعضاء
          _buildInfoRow(
            icon: Icons.people_outline_rounded,
            label: 'عدد الأعضاء',
            value: '${group.memberCount} عضو',
            theme: theme,
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 16),

          // تاريخ الإنشاء
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'تاريخ الإنشاء',
            value: _formatDate(group.createdAt),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCodeSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'كود الدعوة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // الكود نفسه
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  group.inviteCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // زر النسخ
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _copyInviteCode(context),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ كود الدعوة'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${arabicMonths[date.month - 1]} ${date.year}';
  }

  Future<void> _copyInviteCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: group.inviteCode));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('تم نسخ كود الدعوة'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
