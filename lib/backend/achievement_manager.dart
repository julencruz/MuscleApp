import 'package:muscle_app/backend/edit_achievement_stats.dart';
import 'package:muscle_app/backend/notifs_service.dart';

Map<String, dynamic> achievements = {
  'start_journey': {
    'id': 'start_journey',
    'emoji': '🏆',
    'title': 'Getting Started',
    'description': 'Create your first routine.',
  },
  'share_routine': {
    'id': 'share_routine',
    'emoji': '🚀',
    'title': 'Knowledge Launcher',
    'description': 'Publish your first routine on the marketplace.',
  },
  'first_review': {
    'id': 'first_review',
    'emoji': '⭐',
    'title': 'Voice Heard',
    'description': 'Leave your first review on another user\'s routine.',
  },
  'first_training': {
    'id': 'first_training',
    'emoji': '👣',
    'title': 'First Step',
    'description': 'Complete your first logged workout.',
  },
  'streak_7': {
    'id': 'streak_7',
    'emoji': '⏳',
    'title': 'One Week Strong',
    'description': 'Maintain a 7-day streak.',
  },
  'streak_30': {
    'id': 'streak_30',
    'emoji': '💪',
    'title': 'On the Grind',
    'description': 'Maintain a 30-day streak.',
  },
  'streak_90': {
    'id': 'streak_90',
    'emoji': '👷',
    'title': 'Habit Builder',
    'description': 'Maintain a 90-day streak.',
  },
  'explorer': {
    'id': 'explorer',
    'emoji': '🗺️',
    'title': 'Explorer',
    'description': 'Try a routine from the Marketplace section.',
  },
  'mentor_badge': {
    'id': 'mentor_badge',
    'emoji': '🎖',
    'title': 'Mentor Rising',
    'description': 'Receive a review on a routine you uploaded.',
  },
  'legend_badge': {
    'id': 'legend_badge',
    'emoji': '🏅',
    'title': 'Fitness Legend',
    'description': 'At least 1 person added your routine to their library.',
  },
  'early_training': {
    'id': 'early_training',
    'emoji': '🌞',
    'title': 'Morning Warrior',
    'description': 'Complete a workout before 7:00 AM.',
  },
  'night_owl': {
    'id': 'night_owl',
    'emoji': '🌙',
    'title': 'Night Owl',
    'description': 'Finish a workout after 11:00 PM.',
  },
  'focus_mode': {
    'id': 'focus_mode',
    'emoji': '📵',
    'title': 'Undistracted',
    'description': 'Complete a workout using focus mode.',
  },
  'skip_rest_time': {
    'id': 'skip_rest_time',
    'emoji': '⏰',
    'title': 'No time to rest',
    'description': 'Skip the rest time during a workout.',
  },
  'view_warmup': {
    'id': 'view_warmup',
    'emoji': '🔥',
    'title': 'Warm-up Enthusiast',
    'description': 'Press the button to view your warm-up exercises.',
  },
};

class AchievementManager {
  // Singleton
  static final AchievementManager _instance = AchievementManager._internal();
  factory AchievementManager() => _instance;
  AchievementManager._internal();

  Map<String, dynamic> _stats = {};
  bool _isLoaded = false;

  // Obtener stats (en memoria, sin fetch si ya está cargado)
  Map<String, dynamic> getStats() {
    if (!_isLoaded) {
      throw Exception("AchievementManager no inicializado. Llama a initialize() primero.");
    }
    return _stats;
  }

  // Inicialización única (se llama solo una vez al inicio)
  Future<void> initialize() async {
    if (!_isLoaded) {
      try {
        _stats = await editAchievement.getAchievementStats();
      } catch (e) {
        print('Error al cargar los logros en initialize: $e');
        _stats = {}; // Evitas dejarlo null
      }
      _isLoaded = true;
    }
  }

  Future<void> refresh() async {
    try {
      _stats = await editAchievement.getAchievementStats();
    } catch (e) {
      print('Error al refrescar los logros: $e');
      _stats = {}; // También puedes mostrar un snackbar o algo si quieres
    }
  }

  // Desbloquear un achievement (actualiza caché + base de datos)
  Future<bool> unlockAchievement(String achievID, [String? userID]) async {
    if (userID != null) {
      await editAchievement.setAchievementStatsToUser(achievID, userID);
      return true;
    }

    if (!_stats[achievID]) {
      _stats[achievID] = true; // Actualiza caché en memoria
      await editAchievement.setAchievementStats(_stats); // Persiste en DB

      NotifsService.showLocalNotification(
        id: 8,
        title: '🏆 Achievement unlocked! 🚀',
        body: 'You\'ve unlocked the ${achievements[achievID]["title"]} achievement 🎉. Congrats! 💪',
      );
    }
    return true;
  }
}
