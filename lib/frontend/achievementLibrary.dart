import 'package:flutter/material.dart';
import 'package:muscle_app/backend/achievement_manager.dart';


class AchievementLibraryScreen extends StatelessWidget {

  const AchievementLibraryScreen({super.key});

  @override
  Widget build(BuildContext context){
    final achievements = [
      { //Done
        'id': 'start_journey',
        'emoji': '🏆',
        'title': 'Getting Started',
        'description': 'Create your first routine.',
      },
      { //Done
        'id': 'share_routine',
        'emoji': '🚀',
        'title': 'Knowledge Launcher',
        'description': 'Publish your first routine on the marketplace.',
      }, 
      { //Done
        'id': 'first_review',
        'emoji': '⭐',
        'title': 'Voice Heard',
        'description': 'Leave your first review on another user\'s routine.',
      },
      { //Done
        'id': 'first_training',
        'emoji': '👣',
        'title': 'First Step',
        'description': 'Complete your first logged workout.',
      },
      { //Done
        'id': 'streak_7',
        'emoji': '⏳',
        'title': 'One Week Strong',
        'description': 'Maintain a 7-day streak.',
      },
      { //Done
        'id': 'streak_30',
        'emoji': '💪',
        'title': 'On the Grind',
        'description': 'Maintain a 30-day streak.',
      },
      { //Done
        'id': 'streak_90',
        'emoji': '👷',
        'title': 'Habit Builder',
        'description': 'Maintain a 90-day streak.',
      },
      { //Done
        'id': 'explorer',
        'emoji': '🗺️',
        'title': 'Explorer',
        'description': 'Try a routine from the Marketplace section.',
      },
      { //Done
        'id': 'mentor_badge',
        'emoji': '🎖',
        'title': 'Mentor Rising',
        'description': 'Receive a review on a routine you uploaded.',
      }, 
      { //Done
        'id': 'legend_badge',
        'emoji': '🏅',
        'title': 'Fitness Legend',
        'description': 'At least 1 person added your routine to their library.',
      },
      { //Done
        'id': 'early_training',
        'emoji': '🌞',
        'title': 'Morning Warrior',
        'description': 'Complete a workout before 7:00 AM.',
      },
      { //Done
        'id': 'night_owl',
        'emoji': '🌙',
        'title': 'Night Owl',
        'description': 'Finish a workout after 11:00 PM.',
      },
      { //Done
        'id': 'focus_mode',
        'emoji': '📵',
        'title': 'Undistracted',
        'description': 'Complete a workout using focus mode.',
      },
      { //Done
        "id": "skip_rest_time",
        "emoji": "⏰",
        "title": "No time to rest",
        "description": "Skip the rest time during a workout."
      },
      { //Done
        "id": "view_warmup",
        "emoji": "🔥",
        "title": "Warm-up Enthusiast",
        "description": "Press the button to view your warm-up exercises."
      }
    ];

    final unlockedAchievements = AchievementManager().getStats();
    
    void showAchievementDialog(BuildContext context, Map achievement, bool unlocked) {
      // Definir colores y estilos
      final Color accentColor = Colors.red;
      final Color backgroundColor = Colors.white;
      final Color textColor = Colors.black87;
      final Color subtextColor = Colors.black54;
      
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado con badge
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    // Título del logro
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: unlocked ? accentColor.withOpacity(0.1) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: unlocked 
                            ? Text(
                                achievement['emoji'],
                                style: const TextStyle(fontSize: 28),
                              )
                            : ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.grey, Colors.black38],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  achievement['emoji'] ?? "🏆",  
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                unlocked ? "Unlocked" : "Not unlocked",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: unlocked ? accentColor : subtextColor,
                                  fontWeight: unlocked ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Indicador de estado
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: unlocked ? accentColor : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: backgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        unlocked ? Icons.check : Icons.lock,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Descripción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    achievement['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Espacio adicional si está bloqueado (en lugar de la barra de progreso)
                if (!unlocked) ...[
                  const SizedBox(height: 8),
                ],
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botón principal
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final isUnlocked = unlockedAchievements[achievement['id']] ?? false;

            return GestureDetector(
              onTap: () => showAchievementDialog(context, achievement, isUnlocked),
              child: Container(
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isUnlocked
                        ? Text(
                            achievement['emoji'] ?? "🏆",
                            style: const TextStyle(fontSize: 36),
                          )
                        : ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.grey, Colors.black38],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              achievement['emoji'] ?? "🏆",  
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                    const SizedBox(height: 12),
                    Text(
                      achievement['title'] ?? "Error",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isUnlocked ? Colors.black : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
