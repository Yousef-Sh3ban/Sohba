import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/utils/invite_code_generator.dart';
import '../../../../data/models/group_model.dart';

/// Bottom Sheet للانضمام لمجموعة موجودة.
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
            // المقبض
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // العنوان
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.login_rounded,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الانضمام لمجموعة',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'أدخل كود الدعوة الذي حصلت عليه',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // حقل الكود
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
            const SizedBox(height: 24),

            // زر الانضمام
            FilledButton.icon(
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
            const SizedBox(height: 16),

            // ملاحظة
            Container(
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
