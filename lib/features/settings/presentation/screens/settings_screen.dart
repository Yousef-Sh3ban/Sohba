import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app.dart';
import '../../../../core/constants/app_constants.dart';

/// شاشة الإعدادات.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _userName = prefs.getString(userNameKey) ?? '';
      _notificationsEnabled = prefs.getBool(notificationsEnabledKey) ?? true;
      _isLoading = false;
    });
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تغيير الاسم'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'الاسم الجديد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName.length >= 2) {
                final navigator = Navigator.of(dialogContext);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(userNameKey, newName);
                setState(() => _userName = newName);
                navigator.pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, value);
    setState(() => _notificationsEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appState = SohbaApp.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الحساب
          Text(
            'الحساب',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('الاسم'),
                  subtitle: Text(_userName),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _showEditNameDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // قسم المظهر
          Text(
            'المظهر',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('الثيم'),
                  subtitle: Text(_getThemeModeText(appState.themeMode)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => _showThemePicker(appState),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // قسم الإشعارات
          Text(
            'الإشعارات',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('تفعيل الإشعارات'),
                  subtitle: const Text('تذكيرات المهام وإشعارات المجموعة'),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // قسم حول التطبيق
          Text(
            'حول التطبيق',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('الإصدار'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline_rounded),
                  title: const Text('عن صحبة'),
                  subtitle: const Text('تطبيق للتنافس على الخير'),
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'تلقائي (حسب النظام)';
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
    }
  }

  void _showThemePicker(SohbaAppState appState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'اختر الثيم',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('تلقائي (حسب النظام)'),
              value: ThemeMode.system,
              groupValue: appState.themeMode,
              onChanged: (value) {
                appState.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('فاتح'),
              value: ThemeMode.light,
              groupValue: appState.themeMode,
              onChanged: (value) {
                appState.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('داكن'),
              value: ThemeMode.dark,
              groupValue: appState.themeMode,
              onChanged: (value) {
                appState.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            const Text('صحبة'),
          ],
        ),
        content: const Text(
          'تطبيق إسلامي اجتماعي لتشجيع الالتزام بالطاعات من خلال '
          'المجموعات الخاصة والتنافس على الخير مع الأصدقاء.\n\n'
          '﴿ وَتَعَاوَنُوا عَلَى الْبِرِّ وَالتَّقْوَىٰ ﴾',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
