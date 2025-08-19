// lib/models/task.dart
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? note;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  bool isDone;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.note,
    this.dueDate,
    this.isDone = false,
    DateTime? createdAt,
    DateTime? updatedAt, String? categoryId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Null get categoryId => null;
}
