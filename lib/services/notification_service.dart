import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service managing local in-app notifications (Spec §7.1).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the local notifications plugin for Android.
  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);
      _initialized = true;
    } catch (_) {
      // Safe no-op in headless/widget test environments
    }
  }

  /// Displays a heads-up local notification on device.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await init();
      const androidDetails = AndroidNotificationDetails(
        'saagar_audit_escalations',
        'Audit Escalations',
        channelDescription: 'High-urgency audit threshold breach notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (_) {
      // Non-blocking fallback in headless/test environments
    }
  }
}
