import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/widgets/animated_bottom_sheet.dart';
import '../../../../data/models/group_model.dart';

/// Bottom Sheet لإنشاء مجموعة جديدة مع animations سلسة.
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

      if (mounted) {
        widget.onGroupCreated(group);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            const SheetHeader(
              icon: Icons.group_add_rounded,
              title: 'إنشاء مجموعة جديدة',
              subtitle: 'أنشئ مجموعة وشارك الكود مع أصدقائك',
              delay: Duration(milliseconds: 100),
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // حقل الاسم مع animation
            // ═══════════════════════════════════════════════════════════════
            AnimatedFormField(
              delay: 250.ms,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // زر الإنشاء مع animation
            // ═══════════════════════════════════════════════════════════════
            AnimatedActionButton(
              delay: 350.ms,
              child: FilledButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }
}
