import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/group_model.dart';

class GroupSelectionSheet extends StatelessWidget {
  const GroupSelectionSheet({
    required this.groups,
    required this.currentGroupId,
    required this.onGroupSelected,
    required this.onCreateGroup,
    required this.onJoinGroup,
    required this.onLeaveGroup,
    super.key,
  });

  final List<GroupModel> groups;
  final String? currentGroupId;
  final ValueChanged<GroupModel> onGroupSelected;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;
  final ValueChanged<GroupModel> onLeaveGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(
                  Icons.groups_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'مجموعاتك',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لست عضواً في أي مجموعة',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groups.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isSelected = group.id == currentGroupId;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            )
                          : null,
                    ),
                    child: ListTile(
                      onTap: () => onGroupSelected(group),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.withValues(alpha: 0.1),
                        child: Text(
                          group.name.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        group.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${group.memberCount} أعضاء',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryColor,
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => onLeaveGroup(group),
                              tooltip: 'مغادرة المجموعة',
                            ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onJoinGroup,
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('انضم لمجموعة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('مجموعة جديدة'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
