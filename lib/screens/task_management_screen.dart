import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../services/app_constants.dart';
import '../services/task_icons.dart';
import '../services/app_services.dart';
import '../models/task_model.dart';

/// شاشة إدارة المهام بتصميم حديث (للمشرف فقط).
class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String? _groupId;

  StreamSubscription? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _groupId = prefs.getString(lastGroupIdKey);

      if (_groupId != null) {
        _tasksSubscription = AppServices.instance.taskRepository
            .watchTasks(_groupId!)
            .listen((tasks) {
              setState(() {
                _tasks = tasks;
                _isLoading = false;
              });
            });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      developer.log('Error loading tasks: $e', name: 'sohba.tasks');
      setState(() => _isLoading = false);
    }
  }

  void _showAddTaskSheet() {
    if (_tasks.length >= maxTasksPerGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن إضافة أكثر من $maxTasksPerGroup مهمة')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskSheet(
        onSave: (title, description, points, iconId) {
          _addTask(title, description, points, iconId);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditTaskSheet(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskSheet(
        initialTitle: task.title,
        initialDescription: task.description,
        initialPoints: task.points,
        initialIconId: task.iconId,
        isEditing: true,
        onSave: (title, description, points, iconId) {
          _editTask(task, title, description, points, iconId);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _addTask(
    String title,
    String? description,
    int points,
    String iconId,
  ) async {
    if (_groupId == null) return;

    try {
      await AppServices.instance.taskRepository.addTask(
        groupId: _groupId!,
        title: title,
        description: description,
        points: points,
        iconId: iconId,
      );
    } catch (e) {
      developer.log('Error adding task: $e', name: 'sohba.tasks');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ عند إضافة المهمة')),
        );
      }
    }
  }

  Future<void> _editTask(
    TaskModel task,
    String title,
    String? description,
    int points,
    String iconId,
  ) async {
    try {
      await AppServices.instance.taskRepository.updateTask(
        task.copyWith(
          title: title,
          description: description,
          points: points,
          iconId: iconId,
        ),
      );
    } catch (e) {
      developer.log('Error editing task: $e', name: 'sohba.tasks');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ عند تعديل المهمة')),
        );
      }
    }
  }

  void _deleteTask(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: Text('هل أنت متأكد من حذف "${task.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AppServices.instance.taskRepository.deleteTask(
                  _groupId!,
                  task.id,
                );
              } catch (e) {
                developer.log('Error deleting task: $e', name: 'sohba.tasks');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                ? _buildEmptyState()
                : _buildTasksList(),
          ),
          if (!_isLoading && _tasks.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _showAddTaskSheet,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة مهمة جديدة'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              // Title
              Column(
                children: [
                  Text(
                    'إضافة مهمة جديدة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'للمشرف فقط',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_add,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مهام حتى الآن',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف مهام جديدة للمجموعة',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTaskSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مهمة'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addDailyWorshipTasks,
            icon: const Icon(Icons.mosque_rounded),
            label: const Text('إضافة العبادات اليومية'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDailyWorshipTasks() async {
    if (_groupId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة العبادات اليومية'),
        content: const Text(
          'سيتم إضافة 7 مهام جاهزة للعبادات اليومية.\n\nهل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final dailyTasks = [
      {
        'title': 'الصلوات الخمس في جماعة',
        'description': null,
        'points': 50,
        'iconId': 'mosque',
      },
      {
        'title': 'أذكار الصباح والمساء',
        'description': 'قراءة بعض أو كل أذكار الصباح والمساء',
        'points': 20,
        'iconId': 'book',
      },
      {
        'title': 'أذكار النوم',
        'description': null,
        'points': 5,
        'iconId': 'helal',
      },
      {
        'title': 'نصف جزء من القرآن',
        'description': 'التعرض لنصف جزء من القرآن (استماع أو قراءة)',
        'points': 40,
        'iconId': 'quran',
      },
      {
        'title': '20 د فيديو دعوي',
        'description': 'سماع 20 د من أي فيديو دعوي حتى لا تضعف الهمة',
        'points': 10,
        'iconId': 'video',
      },
      {
        'title': 'صلاة الوتر',
        'description': 'لا تنم إلا إذا أوترت حتى لو بـ 10 آيات',
        'points': 20,
        'iconId': 'helal',
      },
      {
        'title': 'صلاة الضحى',
        'description': null,
        'points': 5,
        'iconId': 'star',
      },
    ];

    try {
      for (final task in dailyTasks) {
        await AppServices.instance.taskRepository.addTask(
          groupId: _groupId!,
          title: task['title'] as String,
          description: task['description'] as String?,
          points: task['points'] as int,
          iconId: task['iconId'] as String,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة العبادات اليومية ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإضافة')));
      }
    }
  }

  Widget _buildTasksList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      onReorder: _onReorderTasks,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskItem(task, index);
      },
    );
  }

  Widget _buildTaskItem(TaskModel task, int index) {
    final iconData = TaskIcons.getById(task.iconId);

    final theme = Theme.of(context);
    return Container(
      key: ValueKey(task.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconData.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: iconData.svgPath != null
              ? SvgPicture.asset(
                  iconData.svgPath!,
                  colorFilter: iconData.id == 'alaqsa'
                      ? null
                      : ColorFilter.mode(iconData.color, BlendMode.srcIn),
                )
              : Icon(iconData.icon, color: iconData.color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            ),
          ],
        ),
        subtitle: task.description != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: () => _showEditTaskSheet(task),
              color: AppTheme.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 20),
              onPressed: () => _deleteTask(task),
              color: Colors.red.shade400,
            ),
            const Icon(
              Icons.drag_handle_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _onReorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    });

    // Update order in Firestore
    if (_groupId != null) {
      AppServices.instance.taskRepository.reorderTasks(_groupId!, _tasks);
    }
  }
}

/// Sheet لإضافة أو تعديل مهمة بتصميم حديث.
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({
    this.initialTitle,
    this.initialDescription,
    this.initialPoints = 20,
    this.initialIconId = 'mosque',
    this.isEditing = false,
    required this.onSave,
  });

  final String? initialTitle;
  final String? initialDescription;
  final int initialPoints;
  final String initialIconId;
  final bool isEditing;
  final void Function(
    String title,
    String? description,
    int points,
    String iconId,
  )
  onSave;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _selectedPoints;
  late String _selectedIconId;

  // خيارات النقاط المتاحة
  static const List<int> _pointsOptions = [5, 10, 15, 20, 30, 50];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _selectedPoints = widget.initialPoints;
    _selectedIconId = widget.initialIconId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    widget.onSave(
      _titleController.text.trim(),
      description.isEmpty ? null : description,
      _selectedPoints,
      _selectedIconId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIcon = TaskIcons.getById(_selectedIconId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    _buildSectionTitle('عنوان المهمة *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'مثال: صلاة الفجر في جماعة',
                        filled: true,
                        fillColor:
                            Theme.of(context).cardTheme.color ??
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء إدخال عنوان المهمة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Description field
                    _buildSectionTitle('وصف المهمة (اختياري)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'أضف تفاصيل إضافية عن المهمة...',
                        filled: true,
                        fillColor:
                            Theme.of(context).cardTheme.color ??
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Points selector
                    _buildSectionTitle('عدد النقاط *'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _pointsOptions.map((points) {
                        final isSelected = _selectedPoints == points;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPoints = points),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Theme.of(context).cardTheme.color ??
                                        Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/medal.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                    isSelected
                                        ? Colors.white
                                        : Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color ??
                                              AppTheme.textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                Text(
                                  '$points',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Icon selector
                    _buildSectionTitle('اختر أيقونة المهمة'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: TaskIcons.icons.length,
                      itemBuilder: (context, index) {
                        final iconData = TaskIcons.icons[index];
                        final isSelected = _selectedIconId == iconData.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedIconId = iconData.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Theme.of(context).cardTheme.color ??
                                        Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(context).dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: iconData.svgPath != null
                                ? SvgPicture.asset(
                                    iconData.svgPath!,
                                    colorFilter: iconData.id == 'alaqsa'
                                        ? null
                                        : ColorFilter.mode(
                                            isSelected
                                                ? Colors.white
                                                : iconData.color,
                                            BlendMode.srcIn,
                                          ),
                                  )
                                : Icon(
                                    iconData.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : iconData.color,
                                    size: 24,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Preview
                    _buildSectionTitle('معاينة المهمة ✨'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).cardTheme.color ??
                            Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIcon.id == 'alaqsa'
                                  ? Colors.lightBlue.withValues(alpha: 0.1)
                                  : selectedIcon.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: selectedIcon.svgPath != null
                                ? Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: SvgPicture.asset(
                                      selectedIcon.svgPath!,
                                      colorFilter: selectedIcon.id == 'alaqsa'
                                          ? null
                                          : ColorFilter.mode(
                                              selectedIcon.color,
                                              BlendMode.srcIn,
                                            ),
                                    ),
                                  )
                                : Icon(
                                    selectedIcon.icon,
                                    color: selectedIcon.color,
                                    size: 26,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleController.text.isEmpty
                                      ? 'عنوان المهمة'
                                      : _titleController.text,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                if (_descriptionController.text.isNotEmpty)
                                  Text(
                                    _descriptionController.text,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_selectedPoints',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SvgPicture.asset(
                                  'assets/icons/medal.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(
                    widget.isEditing ? Icons.save_rounded : Icons.add_rounded,
                  ),
                  label: Text(
                    widget.isEditing
                        ? 'حفظ التعديلات'
                        : 'إضافة المهمة للمجموعة +',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}
