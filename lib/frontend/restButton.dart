import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:muscle_app/backend/notifs_service.dart';
import 'package:muscle_app/theme/app_colors.dart';
import 'package:timezone/timezone.dart' as tz;

class RestButton extends StatefulWidget {
  final int initialTime;

  const RestButton({
    super.key,
    this.initialTime = 90,
  });

  @override
  State<RestButton> createState() => _RestButtonState();
}

class _RestButtonState extends State<RestButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => RestTimerModal(initialTime: widget.initialTime),
        );
      },
      onHover: (value) => setState(() => _isHovered = value),
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFFFFD5D5),
      highlightColor: const Color(0xFFFFECEC),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFFFE5E5) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: redColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: redColor,
              ),
              const SizedBox(width: 5),
              Text(
                "Rest",
                style: TextStyle(
                  color: redColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestTimerModal extends StatefulWidget {
  final int initialTime;
  final String? exerciseName;
  final String? skipLabel;

  const RestTimerModal({
    required this.initialTime,
    this.exerciseName,
    this.skipLabel,
  });

  @override
  State<RestTimerModal> createState() => _RestTimerModalState();
}

class _RestTimerModalState extends State<RestTimerModal>
    with TickerProviderStateMixin {
  late int _remainingTime;
  late AnimationController _controller;
  final player = AudioPlayer();
  bool _hasPlayedSound = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialTime;
    _showRestCompletedNotification();

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
            NotifsService.cancelScheduledNotification(0);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.of(context).pop();
            });
          }
        });
      });

    _controller.forward();
  }

  Future<void> _showRestCompletedNotification() async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: _remainingTime-3));
    
    final titles = [
      "Break time's up! 💪",
      "Time to move on! 💪",
      "Ready to continue? 💪",
      "Rest complete! ⚡",
      "Back to work! 🔥"
    ];
    
    final bodies = [
      "Next exercise is waiting! 🏋️‍♂️",
      "Time to crush your next set! 💪",
      "Let's keep that momentum going! 🎯",
      "Ready for your next challenge! 🏆",
      "Back to the grind! 💪"
    ];

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
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FractionallySizedBox(
        heightFactor: 0.65,
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
                const SizedBox(height: 40),
                Text(
                  widget.exerciseName ?? "Rest",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: redColor,
                  ),
                  textAlign: TextAlign.center,
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          redColor,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _formatTime(_remainingTime),
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "seconds remaining",
                          style: TextStyle(
                            fontSize: 14,
                            color: hintColor,
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
                        NotifsService.cancelScheduledNotification(0);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        widget.skipLabel ?? "Skip",
                        style: const TextStyle(fontSize: 16),
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
                        backgroundColor: cardColor,
                        foregroundColor: redColor,
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
      ),
    );
  }
}