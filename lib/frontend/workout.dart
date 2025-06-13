// workout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:muscle_app/backend/calendar_service.dart';
import 'package:muscle_app/backend/get_active_routine.dart';
import 'package:muscle_app/backend/notifs_service.dart';
import 'package:muscle_app/backend/todays_workout.dart';
import 'package:muscle_app/backend/save_stats.dart';
import 'package:muscle_app/backend/shuffle_exercise.dart';
import 'package:muscle_app/backend/update_dock.dart';
import 'package:muscle_app/frontend/achievementLibrary.dart';
import 'package:muscle_app/frontend/calendario.dart';
import 'package:muscle_app/frontend/home.dart';
import 'package:muscle_app/frontend/modofocus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:muscle_app/frontend/infoExercise.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/backend/routine_widget.dart';
import 'package:muscle_app/frontend/warmup.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  @override
  void initState() {
    super.initState();
    NotifsService.requestPermissions();
    _refreshAchievments();
  }

  void _refreshAchievments() async {
    await AchievementManager().refresh();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: const Text('My Workout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<int>(
              future: StatsSaver.getStreak(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return GoalsWidget(streak: snapshot.data ?? 0);
                }
              },
            ),
            const SizedBox(height: 20),
            const DiesWidget(),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>?>(
              future: TodaysWorkout.getTodaysWorkout(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return _buildStartJourneyMessage(context);
                }

                final workoutData = snapshot.data!;
                return TodaysWorkoutWidget(workoutData: workoutData);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStartJourneyMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fitness_center_outlined,
              size: 60,
              color: Color(0xFFA90015),
            ),
            const SizedBox(height: 20),
            const Text(
              'No active routines yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose a routine to begin!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA90015),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage(initialPageIndex: 1)),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Go to Library',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalsWidget extends StatelessWidget {
  final int streak;

  const GoalsWidget({Key? key, required this.streak}) : super(key: key);

  String _getStreakMessage() {
    UpdateDock.updateSystemUI(Colors.white);
    if (streak == 0) {
      return "Start your fitness journey! 🌱";
    } else if (streak == 1) {
        return "First day completed! Something big is cooking 🌟";
    } else if (streak <= 3) {
        return "Building the habit! Keep going 💫";
    } else if (streak <= 7) {
        return "Amazing week! Don't stop now 🔥";
    } else if (streak <= 14) {
        return "Two weeks of dedication! Impressive 💪";
    } else if (streak <= 30) {
        return "One month of consistency! You're unstoppable 👑";
    } else if (streak <= 60) {
        return "Two months of discipline! Extraordinary 🦾";
    } else {
        return "Legendary level reached! Inspiring 🌟";
    }
  }

  Color _getGradientStart() {
    if (streak == 0) return const Color(0xFFFFE0B2); // Naranja más intenso
    if (streak == 1) return const Color(0xFFFFCC80); // Naranja medio
    if (streak <= 3) return const Color(0xFFFFB74D); // Naranja melocotón
    if (streak <= 7) return const Color(0xFFFFB74D); // Naranja medio
    if (streak <= 14) return const Color(0xFFFF9800); // Naranja
    if (streak <= 30) return const Color(0xFFFFA726); // Naranja intenso
    return const Color(0xFFF57C00); // Naranja profundo
  }

  Color _getGradientEnd() {
    if (streak == 0) return const Color(0xFFFFCC80); // Naranja medio
    if (streak == 1) return const Color(0xFFFFB74D); // Naranja melocotón
    if (streak <= 3) return const Color(0xFFFF9800); // Naranja
    if (streak <= 7) return const Color(0xFFFF9800); // Naranja medio
    if (streak <= 14) return const Color(0xFFF57C00); // Naranja intenso
    if (streak <= 30) return const Color(0xFFEF6C00); // Naranja profundo
    return const Color(0xFFE65100); // Naranja rojizo
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AchievementLibraryScreen(),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getGradientStart(),
              _getGradientEnd(),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getGradientEnd().withOpacity(0.1),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            streak.toString(),
                            style: const TextStyle(
                              fontSize: 24, // Ligeramente más pequeño
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "DAYS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: streak > 7 ? 24 : 20, // Más pequeño
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "STREAK",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStreakMessage(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class DiesWidget extends StatefulWidget {
  const DiesWidget({super.key});

  @override
  State<DiesWidget> createState() => _DiesWidgetState();
}

class _DiesWidgetState extends State<DiesWidget> {
  late Future<DayNames> _dayNamesFuture;
  final _service = RoutineService();

  @override
  void initState() {
    super.initState();
    _dayNamesFuture = _service.getAdjacentDayNames();
  }

  Widget _buildWorkoutBox(
      String number,
      String text,
      bool isToday,
      Color bgColor,
      Color textColor,
  ) {
      return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
              color: isToday ? const Color(0xFFA90015) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: isToday ? Colors.transparent : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text(
                      number,
                      style: TextStyle(
                          fontSize: isToday ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : Colors.grey[800],
                      ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      text,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday 
                              ? Colors.white.withOpacity(0.9) 
                              : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                  ),
                  if (isToday) ...[
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                              'TODAY',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                              ),
                          ),
                      ),
                  ],
              ],
          ),
      );
  }

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () async {
        HapticFeedback.lightImpact();
        final daysRegistered = await CalendarService.getDaysRegistered();
        final allowedWeekdays = await CalendarService.getActiveDays();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarioPage(
              daysRegistered: daysRegistered, 
              allowedWeekdays: allowedWeekdays 
            ), 
          ),
        );
      },
        child: FutureBuilder<DayNames>(
          future: _dayNamesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final names = snapshot.data!;
            final now = DateTime.now();
            final yesterday = now.subtract(const Duration(days: 1));
            final tomorrow = now.add(const Duration(days: 1));

            return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA90015).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: const Color(0xFFA90015),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View Calendar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFA90015),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWorkoutBox(
                          '${yesterday.day}',
                          names.yesterday,
                          false,
                          Colors.grey[100]!,
                          Colors.grey[700]!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWorkoutBox(
                          '${now.day}',
                          names.today,
                          true,
                          Colors.transparent,
                          Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWorkoutBox(
                          '${tomorrow.day}',
                          names.tomorrow,
                          false,
                          Colors.grey[100]!,
                          Colors.grey[700]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }


class TodaysWorkoutWidget extends StatefulWidget {
  final Map<String, dynamic> workoutData;

  const TodaysWorkoutWidget({super.key, required this.workoutData});

  @override
  State<TodaysWorkoutWidget> createState() => _TodaysWorkoutWidgetState();
}

class _TodaysWorkoutWidgetState extends State<TodaysWorkoutWidget> {
  late List<List<bool>> seriesDone;
  late List<List<String>> currentWeights;
  late List<List<String>> currentReps;
  late List<List<TextEditingController>> weightControllers;
  late List<List<TextEditingController>> repsControllers;
  Map<int, dynamic> originalExercises = {};
  int? expandedExerciseIndex;
  bool isLoading = true;
  List<Map<String, dynamic>> _allExercises = [];
  bool _forceShowCompletedMessage = false;
  Map<String, dynamic> activeRoutine = {};
  // Buscar el índice del día correspondiente en la lista days
  late int dayIndex;

  @override
  void initState() {
    super.initState();
    //print("WorkoutPage initialized with data: ${widget.workoutData}");
    _initializeWorkoutData();
    _loadAllExercises();
  }

  Future<void> _initializeWorkoutData() async {
    activeRoutine = (await ActiveRoutine.getActiveRoutine())!;
    final todayName = DateFormat('EEEE').format(DateTime.now());

    // Buscar el índice del día correspondiente en la lista days
    dayIndex = activeRoutine['days'].indexWhere(
      (day) => day['weekDay'] == todayName,
    );
    final dayName = widget.workoutData['dayName'];
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('workout_progress_$dayName');

    if (savedData != null && savedData.isNotEmpty) {
      final decoded = json.decode(savedData);

      // Actualizar los ejercicios si hay datos guardados
      if (decoded['exercises'] != null) {
        widget.workoutData['exercises'] = decoded['exercises'];
      }

      setState(() {
        seriesDone = List<List<bool>>.from(
          decoded['seriesDone'].map((x) => List<bool>.from(x)),
        );
        currentWeights = List<List<String>>.from(
          decoded['currentWeights'].map((x) => List<String>.from(x)),
        );
        currentReps = List<List<String>>.from(
          decoded['currentReps'].map((x) => List<String>.from(x)),
        );

        // originalExercises
        if (decoded['originalExercises'] != null) {
          originalExercises = Map<String, dynamic>.from(
            decoded['originalExercises'],
          ).map((key, value) => MapEntry(int.parse(key), value));
        } else {
          originalExercises = {};
        }

        // expandedExerciseIndex
        expandedExerciseIndex = decoded['expandedExerciseIndex'] ?? -1;

        isLoading = false;
      });
    } else {
      final exercises = widget.workoutData['exercises'];
      setState(() {
        seriesDone = exercises.map<List<bool>>((exercise) {
          return List<bool>.filled(exercise['series'] ?? 0, false);
        }).toList();

        currentWeights = exercises.map<List<String>>((exercise) {
          return List<String>.filled(
            exercise['series'] ?? 0,
            exercise['lastWeight']?.toString() ?? '0',
          );
        }).toList();

        currentReps = exercises.map<List<String>>((exercise) {
          // Usar duration si está presente, sino usar reps
          final value = exercise['duration'] ?? exercise['reps'] ?? 0;
          return List<String>.filled(
            exercise['series'] ?? 0,
            value.toString(),
          );
        }).toList();

        originalExercises = {};
        isLoading = false;
      });
    }

    _initializeControllers();
  }

  void _initializeControllers() {
    final exercises = widget.workoutData['exercises'];

    weightControllers = List.generate(exercises.length, (i) {
      return List.generate(
        exercises[i]['series'],
        (j) => TextEditingController(text: currentWeights[i][j]),
      );
    });

    repsControllers = List.generate(exercises.length, (i) {
      return List.generate(
        exercises[i]['series'],
        (j) => TextEditingController(text: currentReps[i][j]),
      );
    });
  }

  Future<void> _saveWorkoutProgress() async {
    final dayName = widget.workoutData['dayName'];
    final prefs = await SharedPreferences.getInstance();

    final dataToSave = {
      'dayName': dayName,
      'exercises': widget.workoutData['exercises'],
      'seriesDone': seriesDone,
      'currentWeights': currentWeights,
      'currentReps': currentReps,
      'originalExercises': originalExercises.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'expandedExerciseIndex': expandedExerciseIndex, 
    };

    await prefs.setString('workout_progress_$dayName', json.encode(dataToSave));
  }

  @override
  void dispose() {
    for (var controllerList in weightControllers) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    for (var controllerList in repsControllers) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _toggleExercise(int index) {
    setState(() {
      if (expandedExerciseIndex == index) {
        expandedExerciseIndex = null;
        _saveWorkoutProgress();
      } else {
        expandedExerciseIndex = index;
        _saveWorkoutProgress();
      }
    });
  }

  double getPRForExercise(int exerciseIndex) {
    if (weightControllers.length <= exerciseIndex) return 0;
    final controllers = weightControllers[exerciseIndex];
    final weights =
        controllers.map((c) => double.tryParse(c.text) ?? 0).toList();
    return weights.isNotEmpty ? weights.reduce((a, b) => a > b ? a : b) : 0;
  }

  Future<void> _loadAllExercises() async {
    final all = await ExerciseLoader.importExercises();
    setState(() {
      _allExercises = all;
    });
    UpdateDock.updateSystemUI(Colors.white);
  }

  Map<String, dynamic>? _findFullExercise(dynamic ex) {
    if (ex['eID'] != null) {
      return _allExercises.firstWhere(
        (e) => e['eID'] == ex['eID'],
        orElse: () => {},
      );
    } else if (ex['exerciseName'] != null) {
      return _allExercises.firstWhere(
        (e) => e['name'] == ex['exerciseName'],
        orElse: () => {},
      );
    }
    return null;
  }

  Widget _buildCircleButton({
  required IconData icon,
  required VoidCallback onPressed,
  VoidCallback? onLongPress,
}) {
  return GestureDetector(
    onLongPress: onLongPress,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          splashColor: const Color(0xFFA90015).withOpacity(0.2),
          highlightColor: const Color(0xFFA90015).withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              icon,
              color: const Color(0xFFA90015),
              size: 32,
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(
        color: Color(0xFFA90015),
      ));
    }

    final dayName = widget.workoutData['dayName'] == "" ? 'Unnamed Day' : widget.workoutData['dayName'];
    final exercises = widget.workoutData['exercises'];
    final bool hasExercises = exercises != null && exercises.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: !hasExercises
              ? _buildNoWorkoutTodayMessage()
              : _buildWorkoutContent(dayName!, exercises),
    );
  }

  Widget _buildNoWorkoutTodayMessage() {
  final workoutData = widget.workoutData;
  return Container(
    width: double.infinity, // Ocupa todo el ancho disponible
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.fitness_center,
          size: 40, // Icono más pequeño
          color: Color(0xFFA90015),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            workoutData['restMessage'] ?? 'Time to recover! 💪',
            style: const TextStyle(
              fontSize: 22, // Tamaño ligeramente reducido
              fontWeight: FontWeight.w600, // Peso intermedio
              color: Colors.black87,
              height: 1.3, // Interlineado mejorado
            ),
            textAlign: TextAlign.center,
            maxLines: 3, // Previene overflow excesivo
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (workoutData['nextWorkoutDay'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'Next workout: ${workoutData['nextWorkoutDay']}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFA90015),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}

  Widget _buildWorkoutContent(String dayName, List exercises) {
    print("Ejercicios: $exercises");
    if (_forceShowCompletedMessage) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: const BoxConstraints(minHeight: 300),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all_rounded, color: Color(0xFFA90015), size: 50),
              const SizedBox(height: 24),
              const Text(
                "Workout completed for today!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Good job. Rest and get ready for the next challenge.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                      children: <TextSpan>[
                        const TextSpan(text: 'Today - '),
                        TextSpan(
                          text: '$dayName',
                          style: const TextStyle(
                            color: Color(0xFFA90015),
                            fontWeight: FontWeight.w600, // Semibold
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  WarmUpButton(dayRoutine: exercises),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    for (int i = 0; i < seriesDone.length; i++) {
                      for (int j = 0; j < seriesDone[i].length; j++) {
                        seriesDone[i][j] = true;
                      }
                    }
                  });

                  bool focus = false;
                  await StatsSaver.saveStats(
                    currentWeights,
                    currentReps,
                    exercises,
                    seriesDone,
                    focus
                  );

                  setState(() {
                    _forceShowCompletedMessage = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA90015,
                  ), // Un rojo un poco más apagado
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bordes menos redondeados
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding más reducido
                  elevation: 2, // Elevación más sutil
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16, // Tamaño de fuente ligeramente menor
                    fontWeight: FontWeight.w600, // Peso de fuente un poco menos intenso
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return GestureDetector(
            onTap: () => _toggleExercise(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: expandedExerciseIndex == index
                  ? _buildExpandedExercise(
                    exercise: exercise['exerciseName'],
                    series: exercise['series'],
                    reps: exercise['reps'],
                    duration: exercise['duration'],
                    exerciseIndex: index,
                  )
                : _buildCollapsedExercise(
                    exercise: exercise['exerciseName'],
                    series: exercise['series'],
                    reps: exercise['reps'],
                    duration: exercise['duration'],
                    exerciseIndex: index,
                  ),
            ),
          );
        }).toList(),
        const SizedBox(height: 30),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircleButton(
                icon: Icons.shuffle_rounded,
                onPressed: () {
                  if (expandedExerciseIndex != null) {
                    _shuffleExercise(expandedExerciseIndex!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select an exercise first')),
                    );
                  }
                },
                onLongPress: () {
                  if (expandedExerciseIndex != null) {
                    _restoreOriginalExercise(expandedExerciseIndex!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select an exercise first')),
                    );
                  }
                },
              ),
              const SizedBox(width: 40),
              _buildCircleButton(
                icon: Icons.play_arrow,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.0), // Un poco más redondeado
                        ),
                        backgroundColor: Colors.white,
                        elevation: 8, // Añadimos una ligera elevación para la sombra
                        titlePadding: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 16), // Más espacio arriba y abajo del título
                        contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 24), // Espacio inferior en los botones
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Alineamos el texto a la izquierda
                          children: [
                            const Text(
                              "Focus Mode",
                              style: TextStyle(
                                fontWeight: FontWeight.w800, // Más negrita
                                fontSize: 28, // Un poco más grande
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 4, // Un poco más grueso
                              width: 72, // Un poco más ancho
                              decoration: BoxDecoration(
                                color: const Color(0xFFA90015),
                                borderRadius: BorderRadius.circular(4), // Bordes más redondeados
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18), // Un poco más de padding
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[300]!, // Un gris un poco más oscuro
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.do_not_disturb_on_outlined,
                                size: 60, // Un poco más grande
                                color: Color(0xFFA90015),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "Silence distractions and focus on your workout.",
                              style: TextStyle(
                                fontSize: 17, // Un poco más grande
                                color: Colors.black87, // Texto principal más oscuro
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "You will not receive notifications while this mode is activated.",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700], 
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14), // Más redondeado
                              ),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.w600, // Más énfasis
                                color: Colors.black54,
                                fontSize: 16, // Un poco más grande
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8), // Espacio entre los botones
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA90015),
                              foregroundColor: Colors.white,
                              elevation: 4, // Ligera elevación en el botón principal
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14), // Más redondeado
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16), // Un poco más de padding vertical
                              shadowColor: const Color(0xFFA90015).withOpacity(0.4), // Sombra un poco más intensa
                            ),
                            child: const Text(
                              "Focus!",
                              style: TextStyle(
                                fontWeight: FontWeight.w700, // Aún más énfasis
                                fontSize: 16, // Un poco más grande
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModoFocusPage(
                                    routine: activeRoutine,
                                    exerciseIndex: 0,
                                    dayIndex: dayIndex,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildCollapsedExercise({
    required String exercise,
    required int series,
    required int? reps,
    required int? duration,
    int? exerciseIndex,
  }) {
    final setsText = duration != null 
        ? '$series x ${duration}s' 
        : '$series x ${reps ?? 0}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (exerciseIndex != null) {
                    final ex = widget.workoutData['exercises'][exerciseIndex];
                    final pr = getPRForExercise(exerciseIndex);
                    final full = _findFullExercise(ex);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InfoExerciseScreen(
                          name: full != null && full.isNotEmpty
                              ? full['name']
                              : (ex['exerciseName'] ?? ''),
                          primaryMuscles: full != null && full.isNotEmpty
                              ? full['primaryMuscles'] ?? []
                              : [],
                          secondaryMuscles: full != null && full.isNotEmpty
                              ? full['secondaryMuscles'] ?? []
                              : [],
                          instructions: full != null && full.isNotEmpty
                              ? full['instructions'] ?? []
                              : [],
                          images: full != null && full.isNotEmpty
                              ? full['images'] ?? []
                              : [],
                          level: full != null && full.isNotEmpty
                              ? full['level'] ?? ''
                              : '',
                          pr: pr,
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Icon(Icons.info_outline_rounded, 
                  color: Color(0xFFA90015), 
                  size: 22),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  exercise,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFA90015).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            setsText,
            style: TextStyle(
              color: Color(0xFFA90015),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.keyboard_arrow_down_rounded, 
          color: Colors.grey[500]),
      ],
    );
  }

  Widget _buildExpandedExercise({
    required String exercise,
    required int series,
    required int? reps,
    required int? duration,
    required int exerciseIndex,
  }) {
    final bool isTimed = duration != null;
    int completedSeries = seriesDone[exerciseIndex].where((done) => done).length;
    int visibleSeries = completedSeries < seriesDone[exerciseIndex].length
        ? completedSeries + 1
        : seriesDone[exerciseIndex].length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con nombre del ejercicio y series x reps/segundos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  // Botón de información
                  InkWell(
                    onTap: () {
                      final ex = widget.workoutData['exercises'][exerciseIndex];
                      final pr = getPRForExercise(exerciseIndex);
                      final full = _findFullExercise(ex);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InfoExerciseScreen(
                            name: full != null && full.isNotEmpty
                                ? full['name']
                                : (ex['exerciseName'] ?? ''),
                            primaryMuscles: full != null && full.isNotEmpty
                                ? full['primaryMuscles'] ?? []
                                : [],
                            secondaryMuscles: full != null && full.isNotEmpty
                                ? full['secondaryMuscles'] ?? []
                                : [],
                            instructions: full != null && full.isNotEmpty
                                ? full['instructions'] ?? []
                                : [],
                            images: full != null && full.isNotEmpty
                                ? full['images'] ?? []
                                : [],
                            level: full != null && full.isNotEmpty
                                ? full['level'] ?? ''
                                : '',
                            pr: pr,
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.info_outline_rounded, 
                      color: Color(0xFFA90015), 
                      size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Nombre del ejercicio
                  Flexible(
                    child: Text(
                      exercise,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Series x Reps/Seconds
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFA90015).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isTimed ? '$series x ${duration}s' : '$series x ${reps}',
                style: TextStyle(
                  color: Color(0xFFA90015),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_up_rounded, color: Colors.grey[500]),
          ],
        ),

        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey[300]),

        // Encabezado de columnas (Set, Kg, Reps/Seconds)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  "Set",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    "Kg",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              if (!isTimed) SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    "Reps",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              if (isTimed) SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    "Secs",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),

        // Lista de series
        Column(
          children: List.generate(visibleSeries, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Número de serie
                  SizedBox(
                    width: 40,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: seriesDone[exerciseIndex][index]
                            ? Color(0xFFA90015)
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Campo de peso (kg)
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: weightControllers[exerciseIndex][index],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'kg',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: seriesDone[exerciseIndex][index]
                            ? Colors.grey[50]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFA90015),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: seriesDone[exerciseIndex][index]
                            ? Colors.grey[400]
                            : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (newValue) {
                        setState(() {
                          currentWeights[exerciseIndex][index] = newValue;
                          _saveWorkoutProgress();
                        });
                      },
                    ),
                  ),

                  // Campo de reps o segundos (según el tipo de ejercicio)
                  if (!isTimed) SizedBox(
                    width: 60,
                    child: TextField(
                      controller: repsControllers[exerciseIndex][index],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'reps',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: seriesDone[exerciseIndex][index]
                            ? Colors.grey[50]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFA90015),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: seriesDone[exerciseIndex][index]
                            ? Colors.grey[400]
                            : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (newValue) {
                        setState(() {
                          currentReps[exerciseIndex][index] = newValue;
                          _saveWorkoutProgress();
                        });
                      },
                    ),
                  ),

                  if (isTimed) SizedBox(
                    width: 60,
                    child: TextField(
                      controller: repsControllers[exerciseIndex][index],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'secs',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: seriesDone[exerciseIndex][index]
                            ? Colors.grey[50]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFFA90015),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: seriesDone[exerciseIndex][index]
                            ? Colors.grey[400]
                            : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (newValue) {
                        setState(() {
                          currentReps[exerciseIndex][index] = newValue;
                          _saveWorkoutProgress();
                        });
                      },
                    ),
                  ),

                  // Checkbox de serie completada
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: seriesDone[exerciseIndex][index],
                      onChanged: (value) {
                        setState(() {
                          seriesDone[exerciseIndex][index] = value!;
                          if (value == true &&
                              index == visibleSeries - 1 &&
                              visibleSeries < seriesDone[exerciseIndex].length) {
                            visibleSeries++;
                          }
                          _saveWorkoutProgress();
                        });
                      },
                      activeColor: Colors.red,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) {
                            return const Color(0xFFA90015);
                          }
                          return Colors.white;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        // Mensaje de ejercicio completado
        if (completedSeries == seriesDone[exerciseIndex].length)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, 
                  color: Color(0xFF00C853), 
                  size: 20),
                const SizedBox(width: 8),
                Text(
                  "Exercise done!",
                  style: TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _shuffleExercise(int exerciseIndex) async {
    try {
      final currentExercise = widget.workoutData['exercises'][exerciseIndex];

      // Guardar solo si no se ha guardado antes
      if (!originalExercises.containsKey(exerciseIndex)) {
        originalExercises[exerciseIndex] = currentExercise;
      }

      final newExercise = await ShuffleExercise.getEquivalentExercise(
        currentExercise,
      );

      if (newExercise['exerciseName'] == currentExercise['exerciseName']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No equivalent exercises available')),
        );
        return;
      }

      final updatedExercises = List<dynamic>.from(
        widget.workoutData['exercises'],
      );
      updatedExercises[exerciseIndex] = newExercise;

      _resetExerciseState(exerciseIndex);

      setState(() {
        widget.workoutData['exercises'] = updatedExercises;
      });

      await _saveWorkoutProgress();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Choose an exercise first')));
    }
  }

  void _restoreOriginalExercise(int exerciseIndex) async {
    final original = originalExercises[exerciseIndex];
    if (original != null) {
      final updatedExercises = List<dynamic>.from(
        widget.workoutData['exercises'],
      );
      updatedExercises[exerciseIndex] = original;

      _resetExerciseState(exerciseIndex);

      setState(() {
        widget.workoutData['exercises'] = updatedExercises;
      });

      await _saveWorkoutProgress();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Original exercise restored!')),
      );
    }
  }

  void _resetExerciseState(int exerciseIndex) {
    final exercise = widget.workoutData['exercises'][exerciseIndex];

    // Asegurar que las listas tengan el tamaño correcto
    if (seriesDone.length <= exerciseIndex) {
      seriesDone.add(List<bool>.filled(exercise['series'], false));
    } else {
      seriesDone[exerciseIndex] = List<bool>.filled(exercise['series'], false);
    }

    if (currentWeights.length <= exerciseIndex) {
      currentWeights.add(
        List<String>.filled(
          exercise['series'],
          exercise['lastWeight']?.toString() ?? '0',
        ),
      );
    } else {
      currentWeights[exerciseIndex] = List<String>.filled(
        exercise['series'],
        exercise['lastWeight']?.toString() ?? '0',
      );
    }

    if (currentReps.length <= exerciseIndex) {
      currentReps.add(
        List<String>.filled(
          exercise['series'],
          exercise['reps']?.toString() ?? '0',
        ),
      );
    } else {
      currentReps[exerciseIndex] = List<String>.filled(
        exercise['series'],
        exercise['reps']?.toString() ?? '0',
      );
    }

    // Limpiar controladores antiguos
    if (weightControllers.length > exerciseIndex) {
      for (var controller in weightControllers[exerciseIndex]) {
        controller.dispose();
      }
    }

    if (repsControllers.length > exerciseIndex) {
      for (var controller in repsControllers[exerciseIndex]) {
        controller.dispose();
      }
    }

    // Crear nuevos controladores
    if (weightControllers.length <= exerciseIndex) {
      weightControllers.add([]);
    }
    weightControllers[exerciseIndex] = List.generate(
      exercise['series'],
      (j) => TextEditingController(text: currentWeights[exerciseIndex][j]),
    );

    if (repsControllers.length <= exerciseIndex) {
      repsControllers.add([]);
    }
    repsControllers[exerciseIndex] = List.generate(
      exercise['series'],
      (j) => TextEditingController(text: currentReps[exerciseIndex][j]),
    );
  }
}
