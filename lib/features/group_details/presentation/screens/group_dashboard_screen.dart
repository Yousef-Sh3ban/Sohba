import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/task_icons.dart';
import '../../../../core/services/app_services.dart';
import '../../../../data/models/group_member_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/task_completion_model.dart';
import '../../../../data/models/task_model.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/empty_groups_view.dart';
import '../widgets/join_group_sheet.dart';

/// الشاشة الرئيسية - لوحة تحكم المجموعة بتصميم حديث.
class GroupDashboardScreen extends StatefulWidget {
  const GroupDashboardScreen({super.key});

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  List<GroupModel> _groups = [];
  GroupModel? _currentGroup;
  List<TaskModel> _tasks = [];
  List<GroupMemberModel> _members = [];
  Map<String, TaskStatus> _myCompletions = {};
  Map<String, TaskCompletionModel> _allCompletions = {};
  String? _userId;
  bool _isLoading = true;
  int _currentNavIndex = 0; // 0 = مهامي، 1 = المجموعة

  StreamSubscription? _tasksSubscription;
  StreamSubscription? _completionsSubscription;
  StreamSubscription? _membersSubscription;

  Timer? _debounceTimer;
  bool _ignoreMyCompletionsStream = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _completionsSubscription?.cancel();
    _membersSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(deviceIdKey);
      final savedGroupId = prefs.getString(lastGroupIdKey);
      final groupIds = prefs.getStringList(userGroupIdsKey) ?? [];

      if (_userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (groupIds.isEmpty) {
        setState(() {
          _groups = [];
          _currentGroup = null;
          _isLoading = false;
        });
        return;
      }

      final groups = <GroupModel>[];
      for (final groupId in groupIds) {
        final group = await AppServices.instance.groupRepository.getGroup(
          groupId,
        );
        if (group != null) {
          groups.add(group);
        }
      }

      if (groups.isEmpty) {
        setState(() {
          _groups = [];
          _currentGroup = null;
          _isLoading = false;
        });
        return;
      }

      GroupModel? activeGroup;
      if (savedGroupId != null) {
        activeGroup = groups.where((g) => g.id == savedGroupId).firstOrNull;
      }
      activeGroup ??= groups.first;

      setState(() {
        _groups = groups;
        _currentGroup = activeGroup;
      });

      _listenToGroupData(activeGroup.id);
    } catch (e) {
      developer.log('Error loading data: $e', name: 'sohba.dashboard');
      setState(() => _isLoading = false);
    }
  }

  void _listenToGroupData(String groupId) {
    _tasksSubscription?.cancel();
    _completionsSubscription?.cancel();
    _membersSubscription?.cancel();

    _tasksSubscription = AppServices.instance.taskRepository
        .watchTasks(groupId)
        .listen((tasks) {
          setState(() {
            _tasks = tasks;
            _isLoading = false;
          });
        });

    _completionsSubscription = AppServices.instance.taskRepository
        .watchTodayCompletions(groupId)
        .listen((completions) {
          final completionsMap = <String, TaskCompletionModel>{};
          for (final c in completions) {
            completionsMap[c.userId] = c;
          }

          setState(() {
            _allCompletions = completionsMap;
            if (!_ignoreMyCompletionsStream &&
                _userId != null &&
                completionsMap.containsKey(_userId)) {
              _myCompletions = completionsMap[_userId]!.tasks;
            }
          });
        });

    _membersSubscription = AppServices.instance.groupRepository
        .watchMembers(groupId)
        .listen((members) {
          setState(() => _members = members);
        });
  }

  void _switchGroup(GroupModel group) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastGroupIdKey, group.id);
    setState(() => _currentGroup = group);
    _listenToGroupData(group.id);
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreateGroupSheet(
        onGroupCreated: (group) {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _showJoinGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => JoinGroupSheet(
        onGroupJoined: (group) {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  Future<void> _updateTaskStatus(String taskId, TaskStatus newStatus) async {
    if (_currentGroup == null || _userId == null) return;

    setState(() {
      _myCompletions[taskId] = newStatus;
      _ignoreMyCompletionsStream = true;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final task = _tasks.firstWhere((t) => t.id == taskId);
        await AppServices.instance.taskRepository.updateTaskCompletion(
          groupId: _currentGroup!.id,
          userId: _userId!,
          taskId: taskId,
          status: newStatus,
          taskPoints: task.points,
        );
      } catch (e) {
        developer.log('Error updating task: $e', name: 'sohba.dashboard');
      } finally {
        if (mounted) {
          setState(() => _ignoreMyCompletionsStream = false);
        }
      }
    });
  }

  TaskStatus _getNextStatus(TaskStatus current) {
    switch (current) {
      case TaskStatus.none:
        return TaskStatus.partial;
      case TaskStatus.partial:
        return TaskStatus.complete;
      case TaskStatus.complete:
        return TaskStatus.none;
    }
  }

  bool _isAdmin() {
    return _currentGroup != null && _currentGroup!.adminId == _userId;
  }

  int _calculateMyTotalPoints() {
    int total = 0;
    for (final task in _tasks) {
      final status = _myCompletions[task.id];
      if (status != null) {
        total += task.getPointsForStatus(status.value);
      }
    }
    return total;
  }

  int _calculateMaxPoints() {
    return _tasks.fold(0, (sum, task) => sum + task.points);
  }

  double _calculateCompletionPercentage() {
    final maxPoints = _calculateMaxPoints();
    if (maxPoints == 0) return 0;
    return (_calculateMyTotalPoints() / maxPoints) * 100;
  }

  int _calculateGroupTotalPoints() {
    int total = 0;
    for (final member in _members) {
      if (member.userId == _userId) {
        total += _calculateMyTotalPoints();
      } else {
        total += _allCompletions[member.userId]?.totalPoints ?? 0;
      }
    }
    return total;
  }

  int _calculateGroupMaxPoints() {
    return _calculateMaxPoints() * _members.length;
  }

  double _calculateGroupPercentage() {
    final maxPoints = _calculateGroupMaxPoints();
    if (maxPoints == 0) return 0;
    return (_calculateGroupTotalPoints() / maxPoints) * 100;
  }

  String _getProgressMessage(double percentage) {
    if (percentage >= 100) {
      return '🎉 أحسنتم! أكملتم جميع المهام';
    } else if (percentage >= 80) {
      return '🔥 رائع! لم يتبق إلا القليل';
    } else if (percentage >= 60) {
      return '💪 استمروا! أنتم في منتصف الطريق';
    } else if (percentage >= 40) {
      return '⭐ بداية جيدة! واصلوا التقدم';
    } else if (percentage >= 20) {
      return '🌱 هيا بنا! كل خطوة تحسب';
    } else if (percentage > 0) {
      return '🚀 ابدأوا رحلتكم اليوم!';
    } else {
      return '⏰ لم يبدأ أحد بعد، كونوا الأوائل!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _groups.isNotEmpty ? _buildBottomNav() : null,
      floatingActionButton:
          _groups.isNotEmpty && _isAdmin() && _currentNavIndex == 1
          ? FloatingActionButton(
              onPressed: () => context.push('/tasks'),
              backgroundColor: Colors.teal,
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppTheme.textPrimary,
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return EmptyGroupsView(
        onCreateGroup: _showCreateGroupSheet,
        onJoinGroup: _showJoinGroupSheet,
      );
    }

    return Column(
      children: [
        _currentNavIndex == 0 ? _buildMyTasksHeader() : _buildGroupHeader(),
        Expanded(
          child: _currentNavIndex == 0
              ? _buildTasksList()
              : _buildLeaderboard(),
        ),
      ],
    );
  }

  Widget _buildMyTasksHeader() {
    final percentage = _calculateCompletionPercentage();
    final myPoints = _calculateMyTotalPoints();
    final maxPoints = _calculateMaxPoints();

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
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Title Centered
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'مهام اليوم',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),

                    // Actions at Start (Right in RTL)
                    Row(
                      children: [
                        // Settings First
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () => context.push('/settings'),
                        ),

                        // Group Menu Second
                        if (_groups.length > 1)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                            ),
                            onSelected: (groupId) {
                              final group = _groups.firstWhere(
                                (g) => g.id == groupId,
                              );
                              _switchGroup(group);
                            },
                            itemBuilder: (context) => _groups
                                .map(
                                  (group) => PopupMenuItem(
                                    value: group.id,
                                    child: Row(
                                      children: [
                                        if (group.id == _currentGroup?.id)
                                          const Icon(
                                            Icons.check,
                                            size: 20,
                                            color: AppTheme.primaryColor,
                                          )
                                        else
                                          const SizedBox(width: 20),
                                        const SizedBox(width: 8),
                                        Text(group.name),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Label (على اليمين في RTL)
                      Row(
                        children: [
                          Text(
                            'تقدمك اليوم',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Percentage (على اليسار في RTL)
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Points
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mainGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$myPoints / $maxPoints',
                          style: const TextStyle(
                            color: AppTheme.cardColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/icons/medal.svg',
                          width: 20,
                          height: 20,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    final percentage = _calculateGroupPercentage();

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
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    // Settings (on the right in RTL)
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => context.push('/settings'),
                    ),
                    const Spacer(),
                    // Group name only
                    Text(
                      _currentGroup?.name ?? 'المجموعة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Members count (on the left in RTL)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_members.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Label (على اليمين في RTL)
                      Row(
                        children: [
                          Text(
                            'ورد اليوم',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Percentage (على اليسار في RTL)
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Message based on progress
                  Text(
                    _getProgressMessage(percentage),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    if (_tasks.isEmpty) {
      return _buildEmptyTasksView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
    );
  }

  Widget _buildEmptyTasksView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد مهام بعد',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isAdmin()
                  ? 'أضف بعض المهام لتبدأ التنافس مع أصدقائك'
                  : 'انتظر حتى يضيف مدير المجموعة بعض المهام',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_isAdmin()) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/tasks'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة مهام'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final status = _myCompletions[task.id] ?? TaskStatus.none;
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
          onTap: () => _updateTaskStatus(task.id, _getNextStatus(status)),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon (يبدأ من اليمين في RTL)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconData.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData.icon, color: iconData.color, size: 26),
                ),
                const SizedBox(width: 14),
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? AppTheme.textSecondary
                                  : null,
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
                ),
                const SizedBox(width: 8),
                // Points badge with medal icon
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                const SizedBox(width: 12),
                // Checkbox with 3 states (على اليسار في RTL)
                GestureDetector(
                  onTap: () =>
                      _updateTaskStatus(task.id, _getNextStatus(status)),
                  child: Container(
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
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : isPartial
                        ? const Icon(
                            Icons.remove_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_members.isEmpty) {
      return const Center(child: Text('لا يوجد أعضاء حالياً'));
    }

    final maxPoints = _calculateMaxPoints();
    final sortedMembers = [..._members];
    sortedMembers.sort((a, b) {
      // Use member.totalPoints for all-time leaderboard
      return b.totalPoints.compareTo(a.totalPoints);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(
                Icons.leaderboard_rounded,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'الأعضاء والتقدم',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/icons/cup.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedMembers.length,
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              final todayPoints = member.userId == _userId
                  ? _calculateMyTotalPoints()
                  : (_allCompletions[member.userId]?.totalPoints ?? 0);

              final percentage = maxPoints > 0
                  ? (todayPoints / maxPoints) * 100
                  : 0.0;

              final displayPoints = member.totalPoints;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: member.userId == _userId
                      ? Border.all(color: AppTheme.accentColor, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with rank
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            member.userName.isNotEmpty
                                ? member.userName[0]
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        // Trophy for first place
                        if (index == 0)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/cup.svg',
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Name and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First row: Name + "أنت" badge
                          Row(
                            children: [
                              Text(
                                member.userName,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (member.userId == _userId) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'أنت',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.accentDark,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Second row: Progress bar + Percentage
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.backgroundColor,
                                    valueColor: AlwaysStoppedAnimation(
                                      percentage >= 100
                                          ? Colors.green
                                          : AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Points badge (gold rounded like the image)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mainGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$displayPoints',
                            style: const TextStyle(
                              color: AppTheme.cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            'assets/icons/medal.svg',
                            width: 18,
                            height: 18,
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Group / Leaderboard (على اليمين في RTL)
              _buildNavItem(
                icon: Icons.groups_outlined,
                activeIcon: Icons.groups_rounded,
                label: 'المجموعة',
                index: 1,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
              // My tasks (على اليسار في RTL)
              _buildNavItem(
                icon: Icons.format_list_bulleted_rounded,
                activeIcon: Icons.format_list_bulleted_rounded,
                label: 'مهامي',
                index: 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isActive = _currentNavIndex == index;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
