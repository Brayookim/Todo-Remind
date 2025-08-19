import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_remind/theme_provider.dart';
import '../providers/task_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance / Theme
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(
                      themeProvider.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.amber
                          : Colors.blue,
                    ),
                    title: Text(
                      themeProvider.themeMode == ThemeMode.dark
                          ? 'Dark Mode'
                          : 'Light Mode',
                    ),
                    subtitle: const Text('Tap to toggle theme'),
                    trailing: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeProvider.setTheme(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                    onTap: () {
                      final isDark = themeProvider.themeMode == ThemeMode.dark;
                      themeProvider.setTheme(
                          isDark ? ThemeMode.light : ThemeMode.dark);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Total Tasks',
                        value: taskProvider.tasks.length.toString(),
                        icon: Icons.task_alt,
                        color: Colors.blue,
                      ),
                      _StatItem(
                        label: 'Completed',
                        value: taskProvider.completedTasks.length.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _StatItem(
                        label: 'Active',
                        value: taskProvider.activeTasks.length.toString(),
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // About / Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Version'),
                    subtitle: Text(appVersion.isNotEmpty ? appVersion : '1.0.0'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate App'),
                    subtitle: const Text('Rate us on Play Store'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rate app coming soon!')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('View privacy policy'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Privacy policy coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
