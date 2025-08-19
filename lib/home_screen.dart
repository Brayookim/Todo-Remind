// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todo_remind/theme_provider.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late Box<Task> _taskBox;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _taskBox = Hive.box<Task>('tasks');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return Icons.wb_sunny;
    if (hour >= 12 && hour < 17) return Icons.wb_sunny_outlined;
    if (hour >= 17 && hour < 20) return Icons.wb_twilight;
    return Icons.nights_stay;
  }

  List<Task> _getTodayTasks() {
    final today = DateTime.now();
    return _taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day &&
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList().reversed.toList();
  }

  List<Task> _getUpcomingTasks() {
    final today = DateTime.now();
    return _taskBox.values.where((task) {
      if (task.dueDate == null) return !task.isDone && task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return task.dueDate!.isAfter(today) &&
          !(task.dueDate!.year == today.year &&
              task.dueDate!.month == today.month &&
              task.dueDate!.day == today.day) &&
          !task.isDone &&
          task.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList().reversed.toList();
  }

  List<Task> _getCompletedTasks() {
    return _taskBox.values
        .where((task) =>
            task.isDone &&
            task.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList().reversed.toList();
  }

  void _toggleTask(Task task) {
    setState(() {
      task.isDone = !task.isDone;
      task.updatedAt = DateTime.now();
      task.save();
    });
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate.isAtSameMomentAs(today)) {
      final hoursLeft = date.difference(now).inHours;
      if (hoursLeft > 0) {
        return 'Due in $hoursLeft hours';
      } else {
        return 'Overdue';
      }
    } else if (taskDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow ${DateFormat('h:mm a').format(date)}';
    } else {
      return 'Due ${DateFormat('MMM d').format(date)}';
    }
  }

  bool _isTaskOverdue(Task task) {
    if (task.dueDate == null || task.isDone) return false;
    return task.dueDate!.isBefore(DateTime.now());
  }

  Widget _buildTaskCard(Task task, Color cardColor, Color textColor, Color secondaryTextColor) {
    final isOverdue = _isTaskOverdue(task);

    return GestureDetector(
      onTap: () => _viewTaskDetails(task),
      onLongPress: () => _showTaskOptions(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleTask(task),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isDone ? Theme.of(context).primaryColor : Colors.transparent,
                    border: Border.all(
                      color: task.isDone ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone ? Colors.grey.shade500 : textColor,
                      ),
                    ),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          task.dueDate != null ? Icons.schedule : Icons.event_busy,
                          size: 14,
                          color: isOverdue ? Colors.red : secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.dueDate != null 
                              ? (isOverdue ? 'Overdue' : _formatDueDate(task.dueDate!))
                              : 'No due date',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : secondaryTextColor,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex, bool isDarkMode) {
    String title, subtitle, emoji;
    
    switch (tabIndex) {
      case 0:
        title = 'No tasks for today';
        subtitle = 'Add a task to get started!';
        emoji = '📝';
        break;
      case 1:
        title = 'No upcoming tasks';
        subtitle = 'Schedule some tasks for later';
        emoji = '📅';
        break;
      case 2:
        title = 'No completed tasks';
        subtitle = 'Complete some tasks to see them here';
        emoji = '✅';
        break;
      default:
        title = 'No tasks';
        subtitle = 'Add a task to get started';
        emoji = '📝';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Text(
                          dueDate == null
                              ? 'Set due date (optional)'
                              : 'Due: ${DateFormat('MMM d, yyyy').format(dueDate!)}',
                          style: TextStyle(
                            color: dueDate == null ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final task = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    note: noteController.text.trim(),
                    isDone: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  if (dueDate != null) {
                    task.dueDate = dueDate;
                  }
                  
                  setState(() {
                    _taskBox.add(task);
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _editTask(Task task) {
    final titleController = TextEditingController(text: task.title);
    final noteController = TextEditingController(text: task.note);
    DateTime? dueDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Text(
                          dueDate == null
                              ? 'Set due date'
                              : 'Due: ${DateFormat('MMM d, yyyy').format(dueDate!)}',
                          style: TextStyle(
                            color: dueDate == null ? Colors.grey.shade600 : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  task.title = titleController.text.trim();
                  task.note = noteController.text.trim();
                  task.dueDate = dueDate;
                  task.updatedAt = DateTime.now();
                  task.save();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task.delete();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(context);
                _editTask(task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Task'),
              onTap: () {
                Navigator.pop(context);
                _deleteTask(task);
              },
            ),
            if (!task.isDone) ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Complete'),
              onTap: () {
                _toggleTask(task);
                Navigator.pop(context);
              },
            ),
            if (task.isDone) ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Mark as Incomplete'),
              onTap: () {
                _toggleTask(task);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _viewTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (task.note != null && task.note!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.note!,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (task.dueDate != null) ...[
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: 'Due Date',
                  value: DateFormat('MMM dd, yyyy • hh:mm a').format(task.dueDate!),
                  color: task.dueDate!.isBefore(DateTime.now()) && !task.isDone
                      ? Colors.red
                      : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey.shade700,
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailItem(
                icon: Icons.event_available,
                title: 'Status',
                value: task.isDone ? 'Completed' : 'Pending',
                color: task.isDone ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildDetailItem(
                icon: Icons.access_time,
                title: 'Created',
                value: DateFormat('MMM dd, yyyy • hh:mm a').format(task.createdAt),
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey.shade700,
              ),
              const SizedBox(height: 16),
              _buildDetailItem(
                icon: Icons.update,
                title: 'Last Updated',
                value: DateFormat('MMM dd, yyyy • hh:mm a').format(task.updatedAt),
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey.shade700,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editTask(task);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Edit Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 85,
      height: 75,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, Theme.of(context).colorScheme.secondary],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(_getTimeIcon(), color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      'Today',
                      _getTodayTasks().where((task) => !task.isDone).length.toString(),
                      primaryColor,
                    ),
                    _buildStatCard(
                      'Tasks',
                      _taskBox.values.length.toString(),
                      Theme.of(context).colorScheme.secondary,
                    ),
                    _buildStatCard(
                      'Done',
                      _getCompletedTasks().length.toString(),
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: primaryColor,
                      unselectedLabelColor: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: 'Today'),
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Completed'),
                      ],
                      onTap: (index) => setState(() {}),
                    ),
                  ),
                  _buildSearchField(isDarkMode),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: _taskBox.listenable(),
                          builder: (context, box, _) {
                            final tasks = _getTodayTasks();
                            return ListView(
                              padding: const EdgeInsets.all(20),
                              children: tasks.isEmpty
                                  ? [_buildEmptyState(0, isDarkMode)]
                                  : tasks.map((task) => _buildTaskCard(task, cardColor, textColor, secondaryTextColor)).toList(),
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: _taskBox.listenable(),
                          builder: (context, box, _) {
                            final tasks = _getUpcomingTasks();
                            return ListView(
                              padding: const EdgeInsets.all(20),
                              children: tasks.isEmpty
                                  ? [_buildEmptyState(1, isDarkMode)]
                                  : tasks.map((task) => _buildTaskCard(task, cardColor, textColor, secondaryTextColor)).toList(),
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: _taskBox.listenable(),
                          builder: (context, box, _) {
                            final tasks = _getCompletedTasks();
                            return ListView(
                              padding: const EdgeInsets.all(20),
                              children: tasks.isEmpty
                                  ? [_buildEmptyState(2, isDarkMode)]
                                  : tasks.map((task) => _buildTaskCard(task, cardColor, textColor, secondaryTextColor)).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}