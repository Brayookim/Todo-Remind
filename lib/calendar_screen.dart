import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Box<Task> taskBox;

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  List<Task> _getTasksForDay(DateTime day) {
    return taskBox.values.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == day.year &&
          task.dueDate!.month == day.month &&
          task.dueDate!.day == day.day;
    }).toList();
  }

  Future<void> _pickMonthYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: "Select Month & Year",
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _getTasksForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: "Go to Today",
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextFormatter: (date, locale) =>
                  "${date.month}/${date.year}",
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              leftChevronVisible: false,
              rightChevronVisible: false,
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onHeaderTapped: (_) => _pickMonthYear(),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedTasks.isEmpty
                ? const Center(
                    child: Text(
                      "No tasks for this day",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            task.isDone
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: task.isDone ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: task.note != null && task.note!.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    task.note!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                )
                              : null,
                          onTap: () {
                            // TODO: Open task details or edit screen
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
