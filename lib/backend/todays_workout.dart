
import 'dart:math';

import 'package:muscle_app/backend/get_active_routine.dart';


class TodaysWorkout {
  static final List<String> _restMessages = [
    "Time to recover for your day to shine! 🌟",
    "Your mooscles are getting bigger! 💪",
    "You’re not AFK, you’re grinding. 🎮",
    "Rest well, sleep better! 😴",
    "Buff strength. Nerf excuses. 💥",
    "Building strength through rest. Keep going! 🔥",
    "Recovery is where the magic happens! ✨",
    "Big rest for a big day coming up! 💪",
    "Your muscles are thanking you! 🎯",
    "Rest day = Growth day! 🌱",
  ];

  static String _getRandomRestMessage(String nextDay) {
    final random = Random();
    String message = _restMessages[random.nextInt(_restMessages.length)];
    return message.replaceAll('{nextDay}', nextDay);
  }

  static Future<Map<String, dynamic>?> getTodaysWorkout() async {
    List<String> weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final activeRoutine = await ActiveRoutine.getActiveRoutine();

    if (activeRoutine != null) {
      DateTime now = DateTime.now();
      String today = weekDays[now.weekday-1];
      var days = activeRoutine["days"];

      for (var day in days) {
        if (day['weekDay'] == today) {
          return {
            'dayName': day['dayName'],
            'exercises': List<Map<String, dynamic>>.from(day['exercises'])
          };
        }
      }

      String nextWorkoutDay = _findNextWorkoutDay(days, today, weekDays);
      String restMessage = _getRandomRestMessage(nextWorkoutDay);

      return {
        'dayName': 'Rest Day',
        'routineName': activeRoutine['name'] ?? 'Active Routine',
        'nextWorkoutDay': nextWorkoutDay,
        'restMessage': restMessage,
        'exercises': []
      };
    }

    return null;
  }
  
  // Método auxiliar para encontrar el próximo día de entrenamiento
  static String _findNextWorkoutDay(List<dynamic> days, String today, List<String> weekDays) {
    int currentDayIndex = weekDays.indexOf(today);
    
    // Busca en los días siguientes de la semana
    for (int i = 1; i <= 7; i++) {
      int nextDayIndex = (currentDayIndex + i) % 7;
      String nextDay = weekDays[nextDayIndex];
      
      for (var day in days) {
        if (day['weekDay'] == nextDay) {
          return nextDay;
        }
      }
    }
    
    return 'No upcoming workouts';
  }
}

