import 'dart:ui';
import 'dart:isolate';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/services/notification_service.dart';

final ReceivePort port = ReceivePort();

@pragma('vm:entry-point')
void backgroundCallback() async {
  final NotificationService notificationService = NotificationService();
  final ApiService apiService = ApiService();

  try {
    final restaurants = await apiService.getRestaurants();
    if (restaurants.isNotEmpty) {
      final restaurant = restaurants[DateTime.now().millisecondsSinceEpoch % restaurants.length];
      
      await notificationService.showNotification(
        title: 'Rekomendasi Restoran Hari Ini!',
        body: '${restaurant.name} di ${restaurant.city} - Rating: ${restaurant.rating}',
      );
    }
  } catch (e) {
    await notificationService.showNotification(
      title: 'Waktunya Makan Siang!',
      body: 'Yuk cek rekomendasi restoran untuk makan siang kamu hari ini.',
    );
  }
}

class BackgroundService {
  static BackgroundService? _instance;
  static const int alarmId = 1;

  BackgroundService._internal() {
    _instance = this;
  }

  factory BackgroundService() => _instance ?? BackgroundService._internal();

  void initializeIsolate() {
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'background_service',
    );
  }

  Future<void> initializeService() async {
    await AndroidAlarmManager.initialize();
  }

  Future<void> schedulePeriodicTask() async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      11, // Schedule for 11 AM
      0,
    );

    // If it's past 11 AM, schedule for tomorrow
    final firstSchedule = now.hour >= 11
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      alarmId,
      backgroundCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      startAt: firstSchedule,
    );
  }

  Future<void> cancelPeriodicTask() async {
    await AndroidAlarmManager.cancel(alarmId);
  }
}