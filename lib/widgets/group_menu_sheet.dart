// ╔═══════════════════════════════════════════════════════════════════════════╗
// ║                         GROUP MENU SHEET                                    ║
// ║  قائمة إدارة المجموعات - بتصميم عصري وأنيق                                 ║
// ╚═══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_theme.dart';
import '../models/group_model.dart';

/// Bottom Sheet أنيق لإدارة المجموعات
class GroupMenuSheet extends StatelessWidget {
  final List<GroupModel> groups;
  final GroupModel? currentGroup;
  final void Function(GroupModel group) onSwitchGroup;
  final VoidCallback? onCreateGroup;
  final VoidCallback? onJoinGroup;
  final VoidCallback? onLeaveGroup;

  const GroupMenuSheet({
    super.key,
    required this.groups,
    required this.currentGroup,
    required this.onSwitchGroup,
    this.onCreateGroup,
    this.onJoinGroup,
    this.onLeaveGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض
          _buildHandle(theme),

          // العنوان
          _buildHeader(theme)
              .animate(delay: 100.ms)
              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.05,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutQuart,
              ),

          // قائمة المجموعات
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildGroupsList(context, theme, isDark),
          ],

          // الفاصل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Divider(color: theme.dividerColor),
          ),

          // أزرار الإجراءات
          _buildActionButtons(context, theme),

          // زر المغادرة
          if (currentGroup != null) _buildLeaveButton(context, theme),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'مجموعاتي',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, ThemeData theme, bool isDark) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group.id == currentGroup?.id;

          return _buildGroupTile(
            context,
            theme,
            group,
            isSelected,
            isDark,
            index,
          );
        },
      ),
    );
  }

  Widget _buildGroupTile(
    BuildContext context,
    ThemeData theme,
    GroupModel group,
    bool isSelected,
    bool isDark,
    int index,
  ) {
    return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                if (!isSelected) onSwitchGroup(group);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                            AppTheme.primaryColor.withValues(alpha: 0.05),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                ),
                child: Row(
                  children: [
                    // أيقونة المجموعة
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.grey.shade700,
                                        Colors.grey.shade800,
                                      ]
                                    : [
                                        Colors.grey.shade200,
                                        Colors.grey.shade300,
                                      ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          group.name.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // معلومات المجموعة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? AppTheme.primaryColor : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 14,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${group.memberCount} أعضاء',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // علامة الاختيار
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: (150 + index * 60).ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideX(
          begin: 0.1,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutQuart,
        );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // زر الانضمام
              Expanded(
                child: _ActionButton(
                  icon: Icons.group_add_rounded,
                  label: 'انضمام لمجموعة',
                  onTap: () {
                    Navigator.pop(context);
                    onJoinGroup?.call();
                  },
                  isPrimary: false,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              // زر الإنشاء
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_circle_rounded,
                  label: 'إنشاء مجموعة',
                  onTap: () {
                    Navigator.pop(context);
                    onCreateGroup?.call();
                  },
                  isPrimary: true,
                  theme: theme,
                ),
              ),
            ],
          ),
        )
        .animate(delay: 300.ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildLeaveButton(BuildContext context, ThemeData theme) {
    return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                onLeaveGroup?.call();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'مغادرة المجموعة الحالية',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: 350.ms)
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutQuart,
        );
  }
}

/// زر إجراء مخصص
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                  )
                : null,
            color: isPrimary ? null : theme.dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : theme.textTheme.bodyMedium?.color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPrimary
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
