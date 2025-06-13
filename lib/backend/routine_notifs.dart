// RoutineNotificationManager.dart
import 'package:muscle_app/backend/notifs_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class RoutineNotificationManager {
  /// Programa notificaciones para cada día de la rutina activa
  static Future<void> scheduleRoutineNotifications(Map<String, dynamic> activeRoutine) async {
    // Cancelar las notificaciones de rutina existentes
    await NotifsService.cancelWorkoutNotifications();
    
    // Extraer días de la rutina
    List<dynamic> days = activeRoutine['days'] ?? [];
    
    if (days.isEmpty) {
      print('No se encontraron días en la rutina activa');
      return;
    }
    
    // Por cada día en la rutina, programar una notificación
    for (var day in days) {
      // Obtener el nombre del día y ejercicios
      String weekDay = day['weekDay'] ?? '';
      List<dynamic> exercises = day['exercises'] ?? [];
      
      // Omitir si no hay ejercicios para este día
      if (exercises.isEmpty) continue;
      
      // Crear un mensaje de notificación
      String exercisesList = exercises
          .map((e) => e['exerciseName'].toString())
          .join(', ');
          
      String title = "Workout day";
      String body = "Today's workout: $exercisesList";
      
      // Programar la notificación para la próxima ocurrencia de este día de la semana a las 8:00 AM
      await _scheduleNextWeekdayNotification(
        weekDay: weekDay,
        title: title,
        body: body,
        dayId: days.indexOf(day),
      );
    }
    
    print('Todas las notificaciones de rutina programadas');
  }
  
  /// Programa una notificación para la próxima ocurrencia del día de la semana especificado a las 8:00 AM
  static Future<void> _scheduleNextWeekdayNotification({
    required String weekDay,
    required String title,
    required String body,
    required int dayId,
  }) async {
    // Convertir el nombre del día de la semana a número (1 = Lunes, 7 = Domingo)
    int targetWeekday = _getWeekdayNumber(weekDay);
    if (targetWeekday == -1) {
      print('Día de la semana inválido: $weekDay');
      return;
    }
    
    // Obtener fecha actual
    final now = tz.TZDateTime.now(tz.local);
    
    // Calcular días hasta la próxima ocurrencia del día objetivo
    int daysUntilTarget = targetWeekday - now.weekday;
    if (daysUntilTarget <= 0) {
      // Si hoy es el día objetivo o ya pasó esta semana,
      // programar para la próxima semana
      daysUntilTarget += 7;
    }
    
    // Crear la fecha objetivo a las 8:00 AM
    final scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilTarget,
      8, // 8 AM
      0,
      0,
    );
    
    // Generar un ID único para esta notificación
    // Usando dayId para asegurar que cada día tenga un ID de notificación único
    int notificationId = 1000 + dayId;
    
    await NotifsService.scheduleWorkoutNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
    
    print('Notificación programada para ${weekDay} a las ${DateFormat('yyyy-MM-dd HH:mm').format(scheduledDate)}');
  }
  
  /// Convierte el nombre del día de la semana a número (1-7)
  static int _getWeekdayNumber(String weekDay) {
    Map<String, int> weekdays = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    
    return weekdays[weekDay] ?? -1;
  }
}