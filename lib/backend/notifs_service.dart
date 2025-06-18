import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

class NotifsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa el servicio (canales, handlers, etc.)
  static Future<void> init() async {
    // Inicializar Timezone
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        // Manejar la respuesta a la notificación (opcional)
        print(
            'onDidReceiveNotificationResponse: ${notificationResponse.payload}');
      },
    );

    // Crear el canal para las notificaciones del temporizador de descanso
    const AndroidNotificationChannel restChannel = AndroidNotificationChannel(
      'rest_timer_channel',
      'Rest Timer Notifications',
      description: 'Notifications for rest timer completion',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('timer1')
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(restChannel);

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general',
      'General Notifications',
      description: 'Notifications for general purposes',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    const AndroidNotificationChannel workoutChannel = AndroidNotificationChannel(
    'workout_routine_channel',
    'Workout Routine Notifications',
    description: 'Notifications for your daily workout routines',
    importance: Importance.high,
    playSound: true,
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(workoutChannel);
  }

  static Future<void> requestPermissions() async {
    // Obtener el estado actual de permisos de notificación
    final NotificationSettings settings = await _messaging.getNotificationSettings();
    print(settings.authorizationStatus);

    // Solicitar permiso si es lunes y no ha sido autorizado o decidido
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined || 
                    settings.authorizationStatus == AuthorizationStatus.denied) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> scheduleWorkoutNotification({
      required int id,
      required String title,
      required String body,
      required tz.TZDateTime scheduledDate,
      bool enableVibration = true,
    }) async {
      print("Scheduled workout notification: $title, $body, $scheduledDate");
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          const AndroidNotificationDetails(
        'workout_routine_channel',
        'Workout Routine Notifications',
        channelDescription: 'Notifications for your daily workout routines',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true, // Usará el sonido predeterminado del sistema
        enableVibration: true,
      );

      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    

    // Añadir esta función para cancelar solo las notificaciones de rutina
    static Future<void> cancelWorkoutNotifications() async {
      // Obtener las notificaciones pendientes
      final pendingNotifications = await _localNotificationsPlugin.pendingNotificationRequests();
      
      // Cancelar solo notificaciones de rutina (IDs 1000 y superiores)
      for (var notification in pendingNotifications) {
        if (notification.id >= 1000) {
          await _localNotificationsPlugin.cancel(notification.id);
          print('Notificación de rutina con ID ${notification.id} cancelada');
        }
      }
    }

    static Future<void> scheduleEndOfDayReminder() async {
    // Cancelar cualquier recordatorio existente primero
    await _localNotificationsPlugin.cancel(999); // ID especial para el recordatorio

    // Obtener la fecha actual
    final now = tz.TZDateTime.now(tz.local);
    
    // Crear la fecha para hoy a las 22:00
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22, // 10 PM
      0,
    );

    // Si ya pasó la hora, no programar
    if (now.isAfter(scheduledDate)) {
      return;
    }

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'Notifications for general purposes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.zonedSchedule(
      999, // ID especial para este tipo de recordatorio
      "Don't forget your progress!",
      "Remember to save today's workout stats",
      scheduledDate,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Recordatorio programado para las 22:00');
  }

  static Future<void> cancelEndOfDayReminder() async {
    await _localNotificationsPlugin.cancel(999);
    print('Recordatorio de fin de día cancelado');
  }

  static Future<void> scheduleRestNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? soundName,
    bool enableVibration = true,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rest_timer_channel',
      'Rest Timer Notifications',
      channelDescription: 'Notifications for rest timer completion',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: soundName != null
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
      enableVibration: enableVibration,
    );

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Muestra una notificación local inmediata
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? soundName,
    bool enableVibration = true,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'Notifications for general purposes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundName != null,
      enableVibration: enableVibration,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Cancela una notificación programada
  static Future<void> cancelScheduledNotification(int id) async {
    await _localNotificationsPlugin.cancel(id);
    print('Notificación con ID $id cancelada');
  }

  /// Cancela todas las notificaciones programadas y mostradas.
  static Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
    print('Todas las notificaciones canceladas');
  }
}


