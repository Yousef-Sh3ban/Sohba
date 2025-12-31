import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/repositories/group_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/user_repository.dart';

/// مزود مركزي للخدمات والـ Repositories.
class AppServices {
  AppServices._();

  static AppServices? _instance;
  static AppServices get instance => _instance ??= AppServices._();

  late final UserRepository userRepository;
  late final GroupRepository groupRepository;
  late final TaskRepository taskRepository;

  bool _initialized = false;

  /// تهيئة جميع الخدمات.
  void initialize({FirebaseFirestore? firestore}) {
    if (_initialized) return;

    final fs = firestore ?? FirebaseFirestore.instance;

    userRepository = UserRepository(firestore: fs);
    groupRepository = GroupRepository(firestore: fs);
    taskRepository = TaskRepository(firestore: fs);

    _initialized = true;
  }
}
