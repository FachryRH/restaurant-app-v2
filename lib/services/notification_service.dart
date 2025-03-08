import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:restaurant_app/services/api_service.dart';

class NotificationService {
  static const String _channelId = 'daily_reminder';
  static const int notificationId = 1;
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidInitialize = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tap
      },
    );
  }

  Future<bool> _requestNotificationPermission(BuildContext context) async {
    final platform =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (platform == null) return false;

    try {
      if (!context.mounted) return false;
      final shouldShowDialog = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Izin Notifikasi'),
              content: const Text(
                  'Aplikasi membutuhkan izin untuk menampilkan notifikasi rekomendasi restoran harian.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Ya'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldShowDialog) return false;

      // Check if we can create notification channel
      const androidNotificationChannel = AndroidNotificationChannel(
        'daily_reminder',
        'Daily Reminder',
        description: 'Restaurant daily reminder notification',
        importance: Importance.high,
      );

      await platform.createNotificationChannel(androidNotificationChannel);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Daily Reminder',
      channelDescription: 'Restaurant daily reminder notification',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleDailyNotification(
      BuildContext context, bool isEnabled) async {
    if (!isEnabled) {
      await cancelDailyNotification();
      return;
    }

    final hasPermission = await _requestNotificationPermission(context);
    if (!hasPermission) {
      return;
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      11, // Schedule for 11 AM
      0,
    );

    // If it's past 11 AM, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      final restaurants = await _apiService.getRestaurants();
      String title = 'Waktunya Makan Siang!';
      String body = 'Yuk cek rekomendasi restoran untuk makan siang kamu hari ini.';

      if (restaurants.isNotEmpty) {
        final restaurant = restaurants[DateTime.now().millisecondsSinceEpoch % restaurants.length];
        title = 'Rekomendasi Restoran Hari Ini!';
        body = '${restaurant.name} di ${restaurant.city} - Rating: ${restaurant.rating}';
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Daily Reminder',
            channelDescription: 'Restaurant daily reminder notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // If there's an error fetching restaurants, schedule a generic notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Waktunya Makan Siang!',
        'Yuk cek rekomendasi restoran untuk makan siang kamu hari ini.',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Daily Reminder',
            channelDescription: 'Restaurant daily reminder notification',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelDailyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }
}
