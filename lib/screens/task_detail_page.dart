import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';

class TaskDetailPage extends StatelessWidget {
  final Task task;
  final int taskKey; // Hive key for CRUD

  const TaskDetailPage({super.key, required this.task, required this.taskKey});

  @override
  Widget build(BuildContext context) {
    final taskBox = Hive.box<Task>('tasks');

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              taskBox.delete(taskKey);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Note
            if (task.note != null && task.note!.isNotEmpty)
              Text(
                task.note!,
                style: const TextStyle(fontSize: 16),
              )
            else
              const Text(
                "No notes added",
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 16),

            // Due Date
            if (task.dueDate != null)
              Text(
                "Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const Spacer(),

            // CRUD Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // update task in Hive
                    final updatedTask = Task(
                      id: task.id,
                      title: task.title,
                      note: task.note,
                      dueDate: task.dueDate,
                      isDone: !task.isDone,
                      createdAt: task.createdAt,
                      updatedAt: DateTime.now(),
                    );

                    taskBox.put(taskKey, updatedTask);
                    Navigator.pop(context);
                  },
                  icon: Icon(task.isDone ? Icons.undo : Icons.check),
                  label: Text(
                    task.isDone ? "Mark as Incomplete" : "Mark as Completed",
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open Edit Task dialog (reuse _showAddTaskDialog)
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
