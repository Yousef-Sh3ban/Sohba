import 'package:flutter/material.dart';

/// أيقونات المهام الإسلامية
class TaskIcons {
  TaskIcons._();

  /// قائمة الأيقونات المتاحة
  static const List<TaskIconData> icons = [
    // New SVGs
    TaskIconData(
      id: 'kaaba',
      svgPath: 'assets/icons/kaaba.svg',
      color: Color(0xFF000000),
      label: 'كعبة',
    ),
    TaskIconData(
      id: 'alaqsa',
      svgPath: 'assets/icons/alaqsa.svg',
      color: Color(0xFF0D4744),
      label: 'الأقصى',
    ),
    TaskIconData(
      id: 'helal',
      svgPath: 'assets/icons/helal.svg',
      color: Color(0xFF5C6BC0),
      label: 'هلال',
    ),
    TaskIconData(
      id: 'star',
      svgPath: 'assets/icons/star.svg',
      color: Color(0xFFFFB300),
      label: 'نجمة',
    ),
    TaskIconData(
      id: 'medal',
      svgPath: 'assets/icons/medal.svg',
      color: Color(0xFFFFD700),
      label: 'ميدالية',
    ),
    TaskIconData(
      id: 'cup',
      svgPath: 'assets/icons/cup.svg',
      color: Color(0xFFFFC107),
      label: 'كأس',
    ),

    // Existing Material Icons (kept if no SVG replacement)
    TaskIconData(
      id: 'prayer',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF1565C0),
      label: 'صلاة',
    ),
    TaskIconData(
      id: 'book',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF6A1B9A),
      label: 'قرآن',
    ),
    TaskIconData(
      id: 'rosary',
      icon: Icons.radio_button_checked_rounded,
      color: Color(0xFFD4A574),
      label: 'تسبيح',
    ),
    TaskIconData(
      id: 'heart',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE53935),
      label: 'عمل خير',
    ),
    TaskIconData(
      id: 'family',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFF00897B),
      label: 'عائلة',
    ),
    TaskIconData(
      id: 'water',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF039BE5),
      label: 'صيام',
    ),
    TaskIconData(
      id: 'handshake',
      icon: Icons.handshake_rounded,
      color: Color(0xFF8D6E63),
      label: 'صدقة',
    ),
  ];

  /// الحصول على أيقونة حسب المعرف
  static TaskIconData getById(String id) {
    return icons.firstWhere((icon) => icon.id == id, orElse: () => icons.first);
  }
}

/// بيانات أيقونة المهمة
class TaskIconData {
  final String id;
  final IconData? icon;
  final String? svgPath;
  final Color color;
  final String label;

  const TaskIconData({
    required this.id,
    this.icon,
    this.svgPath,
    required this.color,
    required this.label,
  }) : assert(icon != null || svgPath != null, 'Must provide icon or svgPath');
}
