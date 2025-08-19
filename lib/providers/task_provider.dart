import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../notification_service.dart';

class TaskProvider extends ChangeNotifier {
  Box<Task>? _taskBox;
  List<Task> _tasks = [];
  int _currentStreak = 0;

  List<Task> get tasks => _tasks.reversed.toList();
  int get currentStreak => _currentStreak;

  List<Task> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == now.year &&
          task.dueDate!.month == now.month &&
          task.dueDate!.day == now.day;
    }).toList().reversed.toList();
  }

  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(today);
    }).toList().reversed.toList();
  }

  List<Task> get completedTasks =>
      _tasks.where((task) => task.isDone).toList().reversed.toList();

  List<Task> get activeTasks =>
      _tasks.where((task) => !task.isDone).toList().reversed.toList();

  TaskProvider() {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _taskBox = await Hive.openBox<Task>('tasks');
    _loadTasks();
    _calculateStats();
  }

  void _loadTasks() {
    _tasks = _taskBox?.values.toList() ?? [];
    notifyListeners();
  }

  void _calculateStats() {
    _currentStreak = _calculateStreak();
    notifyListeners();
  }

  int _calculateStreak() {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final hasCompletedTask = _tasks.any((task) =>
          task.isDone &&
          task.updatedAt.year == date.year &&
          task.updatedAt.month == date.month &&
          task.updatedAt.day == date.day);

      if (hasCompletedTask) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  Future<void> addTask(Task task) async {
    await _taskBox?.put(task.id, task);
    _loadTasks();

    if (task.dueDate != null) {
      await NotificationService.scheduleTaskNotification(
        taskId: int.parse(task.id),
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: task.dueDate!,
      );
    }
  }

  Future<void> updateTask(Task task) async {
    task.updatedAt = DateTime.now();
    await _taskBox?.put(task.id, task);
    _loadTasks();
    _calculateStats();

    await NotificationService.cancelNotification(int.parse(task.id));

    if (task.dueDate != null && !task.isDone) {
      await NotificationService.scheduleTaskNotification(
        taskId: int.parse(task.id),
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: task.dueDate!,
      );
    }
  }

  Future<void> toggleTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.isDone = !task.isDone;

    if (task.isDone) {
      await NotificationService.cancelNotification(int.parse(taskId));
    } else {
      if (task.dueDate != null) {
        await NotificationService.scheduleTaskNotification(
          taskId: int.parse(task.id),
          title: 'Task Reminder',
          body: task.title,
          scheduledDate: task.dueDate!,
        );
      }
    }

    await updateTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskBox?.delete(taskId);
    await NotificationService.cancelNotification(int.parse(taskId));
    _loadTasks();
    _calculateStats();
  }
}
