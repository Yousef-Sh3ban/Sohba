import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/task_icons.dart';
import '../../../../data/models/task_completion_model.dart'; // TaskStatus
import '../../../../data/models/task_model.dart';

/// كارت المهمة - يعرض تفاصيل المهمة مع حالة الإكمال
///
/// يدعم 3 حالات:
/// - [TaskStatus.none] - غير مكتمل
/// - [TaskStatus.partial] - مكتمل جزئياً
/// - [TaskStatus.complete] - مكتمل بالكامل
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.status,
    required this.onStatusChange,
  });

  /// بيانات المهمة
  final TaskModel task;

  /// الحالة الحالية للمهمة
  final TaskStatus status;

  /// Callback عند تغيير الحالة
  final VoidCallback onStatusChange;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == TaskStatus.complete;
    final isPartial = status == TaskStatus.partial;
    final iconData = TaskIcons.getById(task.iconId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isCompleted
            ? Border.all(color: AppTheme.accentColor, width: 2)
            : isPartial
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStatusChange,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ─────────────────────────────────────────────────────────────
                // أيقونة المهمة (يبدأ من اليمين في RTL)
                // ─────────────────────────────────────────────────────────────
                _buildIcon(iconData),
                const SizedBox(width: 14),

                // ─────────────────────────────────────────────────────────────
                // عنوان ووصف المهمة
                // ─────────────────────────────────────────────────────────────
                _buildTitleAndDescription(context, isCompleted),
                const SizedBox(width: 8),

                // ─────────────────────────────────────────────────────────────
                // شارة النقاط مع أيقونة الميدالية
                // ─────────────────────────────────────────────────────────────
                _buildPointsBadge(),
                const SizedBox(width: 12),

                // ─────────────────────────────────────────────────────────────
                // Checkbox ثلاثي الحالات (فارغ / جزئي / مكتمل)
                // ─────────────────────────────────────────────────────────────
                _buildCheckbox(isCompleted, isPartial),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء أيقونة المهمة
  Widget _buildIcon(TaskIconData iconData) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: iconData.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: iconData.svgPath != null
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                iconData.svgPath!,
                colorFilter: iconData.id == 'alaqsa'
                    ? null
                    : ColorFilter.mode(iconData.color, BlendMode.srcIn),
              ),
            )
          : Icon(iconData.icon, color: iconData.color, size: 26),
    );
  }

  /// بناء العنوان والوصف
  Widget _buildTitleAndDescription(BuildContext context, bool isCompleted) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? AppTheme.textSecondary : null,
            ),
          ),
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// بناء شارة النقاط
  Widget _buildPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.mainGold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${task.points}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.cardColor,
            ),
          ),
          const SizedBox(width: 4),
          SvgPicture.asset(
            'assets/icons/medal.svg',
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(
              AppTheme.cardColor,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء Checkbox ثلاثي الحالات
  Widget _buildCheckbox(bool isCompleted, bool isPartial) {
    return GestureDetector(
      onTap: onStatusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppTheme.accentColor
              : isPartial
              ? Colors.orange
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted
                ? AppTheme.accentColor
                : isPartial
                ? Colors.orange
                : AppTheme.textSecondary,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : isPartial
            ? const Icon(Icons.remove_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
