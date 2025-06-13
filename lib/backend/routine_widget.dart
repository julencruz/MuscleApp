// routine_service.dart
import 'package:muscle_app/backend/get_active_routine.dart';

/// Modelo para almacenar los nombres de ayer, hoy y mañana
class DayNames {
  final String yesterday;
  final String today;
  final String tomorrow;

  DayNames({
    required this.yesterday,
    required this.today,
    required this.tomorrow,
  });
}

/// Servicio modular para obtener los nombres de día desde Firebase
  class RoutineService {
    Future<DayNames> getAdjacentDayNames() async {
    try {
      // Obtener la rutina activa usando el servicio existente
      final activeRoutine = await ActiveRoutine.getActiveRoutine();
      
      if (activeRoutine == null) {
        return DayNames(yesterday: '', today: '', tomorrow: '');
      }

      print(activeRoutine['days']);

      // Crear array de 7 días con nombres vacíos
      List<String> weekDays = List.filled(7, 'Rest');
      
      // Rellenar los nombres de los días disponibles
      final days = List<Map<String, dynamic>>.from(activeRoutine['days'] ?? []);
      for (var day in days) {
        int dayIndex = _getWeekDayIndex(day['weekDay']);

        if (dayIndex >= 0) {
          print(day);
          if (day['dayName'] == null) {
            weekDays[dayIndex] = "Rest";
          } else if (day['dayName'] == "") {
            weekDays[dayIndex] = "Unnamed";
          } else {
            weekDays[dayIndex] = day['dayName'];
          }
        }
      }

      // Obtener índices para ayer, hoy y mañana
      final now = DateTime.now();
      final todayIndex = now.weekday - 1;
      final yesterdayIndex = (todayIndex - 1 + 7) % 7;
      final tomorrowIndex = (todayIndex + 1) % 7;

      print('Hoy: ${weekDays[todayIndex]}');
      print('Ayer: ${weekDays[yesterdayIndex]}');
      print('Mañana: ${weekDays[tomorrowIndex]}');

      return DayNames(
        yesterday: weekDays[yesterdayIndex],
        today: weekDays[todayIndex],
        tomorrow: weekDays[tomorrowIndex],
      );
    } catch (e) {
      print('Error getting day names: $e');
      return DayNames(yesterday: '', today: '', tomorrow: '');
    }
  }

  int _getWeekDayIndex(String weekDay) {
    final Map<String, int> dayToIndex = {
      'Monday': 0,
      'Tuesday': 1,
      'Wednesday': 2,
      'Thursday': 3,
      'Friday': 4,
      'Saturday': 5,
      'Sunday': 6,
    };
    return dayToIndex[weekDay] ?? -1;
  }
}
