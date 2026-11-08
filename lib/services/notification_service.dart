import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize({Function(String? payload)? onSelectNotification}) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (onSelectNotification != null) {
          onSelectNotification(response.payload);
        }
      },
    );
  }

  Future<void> showCallEndedNotification({
    required String phoneNumber,
    String? contactName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'call_ended_channel',
      'Telefonate Terminate',
      channelDescription: 'Suggerisce la creazione di un appuntamento post-chiamata',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Chiamata terminata',
      actions: [
        AndroidNotificationAction(
          'action_voice',
          '🎙️ Crea con Voce',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_dismiss',
          'Ignora',
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = contactName != null
        ? 'Chiamata con $contactName terminata'
        : 'Chiamata con $phoneNumber terminata';

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      'Tocca per creare subito un appuntamento a calendario',
      notificationDetails,
      payload: '$phoneNumber|${contactName ?? ""}',
    );
  }
}
