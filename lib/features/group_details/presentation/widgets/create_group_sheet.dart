import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_services.dart';
import '../../../../data/models/group_model.dart';

/// Bottom Sheet لإنشاء مجموعة جديدة.
class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({required this.onGroupCreated, super.key});

  /// callback عند إنشاء المجموعة بنجاح.
  final void Function(GroupModel group) onGroupCreated;

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  GroupModel? _createdGroup;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(deviceIdKey) ?? '';
      final userName = prefs.getString(userNameKey) ?? '';

      // إنشاء المجموعة في Firestore
      final group = await AppServices.instance.groupRepository.createGroup(
        name: _nameController.text.trim(),
        adminId: userId,
        adminName: userName,
      );

      // حفظ معرف المجموعة محلياً
      final groupIds = prefs.getStringList(userGroupIdsKey) ?? [];
      if (!groupIds.contains(group.id)) {
        groupIds.add(group.id);
        await prefs.setStringList(userGroupIdsKey, groupIds);
      }
      await prefs.setString(lastGroupIdKey, group.id);

      setState(() {
        _createdGroup = group;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
      }
    }
  }

  void _shareInviteCode() {
    if (_createdGroup == null) return;

    final text =
        '''
انضم لمجموعة "${_createdGroup!.name}" في تطبيق صحبة!

كود الدعوة: ${_createdGroup!.inviteCode}

حمّل التطبيق وأدخل الكود للانضمام.
''';

    SharePlus.instance.share(ShareParams(text: text));
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
      child: _createdGroup != null
          ? _buildSuccessView(theme, colorScheme)
          : _buildFormView(theme, colorScheme),
    );
  }

  Widget _buildFormView(ThemeData theme, ColorScheme colorScheme) {
    return Form(
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
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.group_add_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إنشاء مجموعة جديدة',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      'أنشئ مجموعة وشارك الكود مع أصدقائك',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // حقل الاسم
          Text('اسم المجموعة', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'مثال: أصدقاء المسجد',
              prefixIcon: Icon(Icons.group_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال اسم المجموعة';
              }
              if (value.trim().length < 3) {
                return 'الاسم قصير جداً';
              }
              if (value.trim().length > 50) {
                return 'الاسم طويل جداً';
              }
              return null;
            },
            onFieldSubmitted: (_) => _createGroup(),
          ),
          const SizedBox(height: 24),

          // زر الإنشاء
          FilledButton.icon(
            onPressed: _isLoading ? null : _createGroup,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: const Text('إنشاء المجموعة'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
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
        const SizedBox(height: 32),

        // أيقونة النجاح
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // الرسالة
        Text(
          'تم إنشاء المجموعة بنجاح!',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _createdGroup!.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // كود الدعوة
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                'كود الدعوة',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _createdGroup!.inviteCode,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // الأزرار
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareInviteCode,
                icon: const Icon(Icons.share_rounded),
                label: const Text('مشاركة'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => widget.onGroupCreated(_createdGroup!),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('متابعة'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
