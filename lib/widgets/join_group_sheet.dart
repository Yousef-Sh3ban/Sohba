import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_constants.dart';
import '../services/app_services.dart';
import '../services/invite_code_generator.dart';
import '../widgets/animated_bottom_sheet.dart';
import '../models/group_model.dart';

/// Bottom Sheet للانضمام لمجموعة موجودة مع animations سلسة.
class JoinGroupSheet extends StatefulWidget {
  const JoinGroupSheet({required this.onGroupJoined, super.key});

  /// callback عند الانضمام للمجموعة بنجاح.
  final void Function(GroupModel group) onGroupJoined;

  @override
  State<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<JoinGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(deviceIdKey) ?? '';
      final userName = prefs.getString(userNameKey) ?? '';
      final normalizedCode = InviteCodeGenerator.normalize(
        _codeController.text,
      );

      // الانضمام للمجموعة
      final group = await AppServices.instance.groupRepository.joinGroup(
        inviteCode: normalizedCode,
        userId: userId,
        userName: userName,
      );

      if (group == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لم يتم العثور على مجموعة بهذا الكود';
        });
        return;
      }

      // حفظ معرف المجموعة محلياً
      final groupIds = prefs.getStringList(userGroupIdsKey) ?? [];
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        await prefs.setStringList(userGroupIdsKey, groupIds);
      }
      await prefs.setString(lastGroupIdKey, group.id);

      if (mounted) {
        widget.onGroupJoined(group);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('ممتلئة')
            ? 'المجموعة ممتلئة'
            : 'حدث خطأ، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // المقبض مع animation
            // ═══════════════════════════════════════════════════════════════
            const SheetHandle(),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // العنوان مع animations
            // ═══════════════════════════════════════════════════════════════
            SheetHeader(
              icon: Icons.login_rounded,
              iconBackgroundColor: colorScheme.secondaryContainer,
              iconColor: colorScheme.secondary,
              title: 'الانضمام لمجموعة',
              subtitle: 'أدخل كود الدعوة الذي حصلت عليه',
              delay: 100.ms,
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // حقل الكود مع animation
            // ═══════════════════════════════════════════════════════════════
            AnimatedFormField(
              delay: 250.ms,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كود الدعوة', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(6),
                      UpperCaseTextFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: 'ABC123',
                      prefixIcon: const Icon(Icons.key_rounded),
                      errorText: _errorMessage,
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال كود الدعوة';
                      }
                      if (!InviteCodeGenerator.isValidFormat(value)) {
                        return 'كود غير صالح';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _joinGroup(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // زر الانضمام مع animation
            // ═══════════════════════════════════════════════════════════════
            AnimatedActionButton(
              delay: 350.ms,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _joinGroup,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text('انضمام'),
              ),
            ),
            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════════════
            // ملاحظة مع animation
            // ═══════════════════════════════════════════════════════════════
            AnimatedInfoBox(
              delay: 420.ms,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'احصل على كود الدعوة من صديقك الذي أنشأ المجموعة',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text formatter لتحويل النص إلى أحرف كبيرة.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
