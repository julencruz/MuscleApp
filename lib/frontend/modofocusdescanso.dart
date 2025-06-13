import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:muscle_app/backend/notifs_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:muscle_app/backend/achievement_manager.dart';

class ModoFocusDescansoPage extends StatefulWidget {
  final String exerciseTitle;
  final VoidCallback onDescansoCompleto;
  final int initialTime;

  const ModoFocusDescansoPage({
    super.key,
    required this.exerciseTitle,
    required this.onDescansoCompleto,
    this.initialTime = 90, // Tiempo de descanso predeterminado de 90 segundos
  });

  @override
  State<ModoFocusDescansoPage> createState() => _ModoFocusDescansoPageState();
}

class _ModoFocusDescansoPageState extends State<ModoFocusDescansoPage>
    with TickerProviderStateMixin {
  late int _remainingTime;
  late AnimationController _controller;
  final player = AudioPlayer();
  bool _hasPlayedSound = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialTime;

    // 🔔 Programar notificación desde el inicio del descanso
    _showRestCompletedNotification();  // ✅

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.initialTime),
    )..addListener(() {
        setState(() {
          _remainingTime = widget.initialTime -
              (_controller.value * widget.initialTime).floor();

          if (_remainingTime == 3 && !_hasPlayedSound) {
            _hasPlayedSound = true;
            player.play(AssetSource('sounds/timer1.mp3'));
          }

          if (_remainingTime == 0) {
            _controller.stop();
            if (_isAppInForeground()){
              NotifsService.cancelScheduledNotification(0);
            }
            Future.delayed(const Duration(milliseconds: 500), () {
              widget.onDescansoCompleto();
            });
          }
        });
      });

    _controller.forward();
  }

  bool _isAppInForeground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == AppLifecycleState.resumed;
}

  Future<void> _showRestCompletedNotification() async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: _remainingTime-3));
    
    print("Scheduled date: $scheduledDate");

    // Lista de títulos aleatorios
    final titles = [
      "Rest's over! 💪",
      "Break time's up! 💪",
      "Time to move on! 💪",
      "Next set's ⏰",
      "Next set awaits! 🏋️‍♂️",
      "Recharged! ⚡"
    ];

    // Lista de cuerpos aleatorios
    final bodies = [
      "Next up: ${widget.exerciseTitle} 🏋️‍♂️",
      "${widget.exerciseTitle} is waiting! 💪",
      "Get ready for ${widget.exerciseTitle}! 🎯",
      "Time for ${widget.exerciseTitle}! 🏆",
      "${widget.exerciseTitle} coming up!"
    ];

    // Seleccionar aleatoriamente
    final random = Random();
    final title = titles[random.nextInt(titles.length)];
    final body = bodies[random.nextInt(bodies.length)];

    await NotifsService.scheduleRestNotification(
      id: 0,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      soundName: 'timer1',
      enableVibration: true,
    );
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.65, // Máximo 65% del alto de pantalla
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                widget.exerciseTitle,
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Rest!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA90015),
                ),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 1 - _controller.value,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFA90015),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _formatTime(_remainingTime),
                        style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "seconds remaining",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AchievementManager().unlockAchievement("skip_rest_time");
                      _controller.stop();
                      widget.onDescansoCompleto();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA90015),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "Skip rest",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.isAnimating) {
                        _controller.stop();
                      } else {
                        _controller.forward(
                          from: _controller.value == 1 ? 0 : _controller.value,
                        );
                      }
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 216, 216, 216),
                      foregroundColor: const Color(0xFFA90015),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 60),
                    ),
                    child: Icon(
                      _controller.isAnimating ? Icons.pause : Icons.play_arrow,
                      size: 30,
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
}