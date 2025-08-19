// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback when notification is tapped
  static void Function(String? payload)? onNotificationTap;

  /// Initialize notifications
  static Future<void> init({void Function(String? payload)? onNotificationTap}) async {
    NotificationService.onNotificationTap = onNotificationTap;

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (NotificationService.onNotificationTap != null) {
          NotificationService.onNotificationTap!(payload);
        }
      },
    );

    // Initialize timezone database
    tz.initializeTimeZones();
  }

  /// Handle notification tapped when app was terminated
  static Future<void> handleInitialNotification() async {
    final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;
      if (payload != null && onNotificationTap != null) {
        // Delay to ensure navigatorKey is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          onNotificationTap!(payload);
        });
      }
    }
  }

  /// Schedule a task notification
  static Future<void> scheduleTaskNotification({
    required int taskId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      taskId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'todo_remind_channel',
          'TodoRemind Notifications',
          channelDescription: 'Reminds you about your tasks',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: "task:$taskId", // ✅ task notification payload
    );
  }

  /// Schedule a general notification
  static Future<void> scheduleGeneralNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate, required String payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'todo_remind_channel',
          'TodoRemind Notifications',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: "notif", // ✅ general notification payload
    );
  }

  /// Cancel a single notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
