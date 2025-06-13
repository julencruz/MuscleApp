import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muscle_app/backend/update_dock.dart';

class ViewRoutine extends StatefulWidget {
  final Map<String, dynamic> routine;

  const ViewRoutine({
    Key? key,
    required this.routine,
  }) : super(key: key);

  @override
  State<ViewRoutine> createState() => _ViewRoutineState();
}

class _ViewRoutineState extends State<ViewRoutine> {
  final List<String> _weekdaysShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late List<bool> _selectedDays;
  late Map<int, Map<String, dynamic>> _exercisesByDay;
  final List<Color> _routineColors = [
    Colors.red[400]!,
    Colors.blue[600]!,
    Colors.green[700]!,
    Colors.orange[600]!,
    Colors.indigo[600]!,
    Colors.teal[600]!,
    Colors.deepPurple[600]!,
  ];

  final List<IconData> _routineIcons = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.sports_mma,
    Icons.sports_handball,
    Icons.sports_baseball,
    Icons.sports_basketball,
    Icons.sports_football,
  ];


  @override
  void initState() {
    super.initState();
    _initializeRoutineData();
  }

  void _initializeRoutineData() {
    print(widget.routine);
    _selectedDays = List.generate(7, (_) => false);
    _exercisesByDay = {};

    final days = widget.routine['days'] as List<dynamic>? ?? [];

    for (var day in days) {
      final dayName = day['dayName'] as String? ?? 'Unnamed Day';
      final exercises = day['exercises'] as List<dynamic>? ?? [];
      final weekDay = day['weekDay'] as String?;

      if (weekDay != null) {
        final dayIndex = _weekdaysFull.indexOf(weekDay);
        if (dayIndex == -1) continue;

        if (exercises.isNotEmpty) {
          _selectedDays[dayIndex] = true;
        }

        _exercisesByDay[dayIndex] = {
          'dayName': dayName,
          'exercises': exercises.map<Map<String, dynamic>>((exercise) {
            return {
              'id': exercise['exerciseID'] ?? dayName,
              'name': exercise['exerciseName'] ?? 'Unnamed Exercise',
              'reps': exercise['reps'],
              'duration': exercise['duration'],
              'series': (exercise['series'] is List
                  ? exercise['series'].length
                  : exercise['series'] ?? 0),
            };
          }).toList(),
        };
      }
    }
  }

  Future<Map<String, dynamic>> _getRoutineInfo(List<Map<String, dynamic>> days, int restTime, {int restBetweenExercises = 120}) async {
    try {
      final String data = await rootBundle.loadString('assets/exercises.json');
      final List<dynamic> allExercises = json.decode(data);

      Map<String, int> levelToValue = {
        "beginner": 1,
        "intermediate": 2,
        "expert": 3,
      };

      int maxLevel = 1;
      Set<String> allMuscles = {};
      int totalTimeInSecs = 0;
      int trainingDays = 0;

      for (var day in days) {
        final dayExercises = day['exercises'] as List? ?? [];
        if (dayExercises.isEmpty) continue;

        trainingDays++;
        int dayTimeInSecs = 0;

        for (var exercise in dayExercises) {
          final exerciseId = exercise['exerciseID']?.toString();
          if (exerciseId == null) continue;

          final exerciseData = allExercises.firstWhere(
            (ex) => ex["id"]?.toString() == exerciseId,
            orElse: () => null,
          );

          if (exerciseData != null) {
            // Procesar nivel
            String level = (exerciseData["level"]?.toString() ?? "beginner").toLowerCase();
            int levelValue = levelToValue[level] ?? 2;
            maxLevel = max(maxLevel, levelValue);

            // Procesar músculos
            List<String> primaryMuscles = List<String>.from(exerciseData["primaryMuscles"] ?? []);
            List<String> secondaryMuscles = List<String>.from(exerciseData["secondaryMuscles"] ?? []);
            allMuscles.addAll(primaryMuscles);
            allMuscles.addAll(secondaryMuscles);

            // Calcular tiempo
            int series = (exercise['series'] as num? ?? 0).toInt();
            int reps = (exercise['reps'] as num? ?? 0).toInt();
            int duration = (exercise['duration'] as num? ?? 0).toInt();

            if (duration > 0) {
              dayTimeInSecs += series * duration;
            } else {
              dayTimeInSecs += series * reps * 5; // 5 segundos por rep
            }
            
            dayTimeInSecs += (series - 1) * restTime;
          }
        }

        if (dayExercises.length > 1) {
          dayTimeInSecs += (dayExercises.length - 1) * restBetweenExercises;
        }

        totalTimeInSecs += dayTimeInSecs;
      }

      String formatDuration(int totalSeconds) {
        if (totalSeconds < 60) return "1 min";

        int hours = totalSeconds ~/ 3600;
        int remainingSecs = totalSeconds % 3600;
        int minutes = (remainingSecs / 60).ceil();

        if (minutes == 60) {
          hours += 1;
          minutes = 0;
        }

        return hours > 0 ? "$hours h $minutes min" : "$minutes min";
      }

      return {
        'totalTime': formatDuration(totalTimeInSecs),
        'averageTime': trainingDays > 0 ? formatDuration((totalTimeInSecs / trainingDays).ceil()) : "0 min",
        'allMuscles': allMuscles.toList()..sort(),
        'routineLevel': levelToValue.entries.firstWhere((e) => e.value == maxLevel, orElse: () => levelToValue.entries.first).key,
        'allExercises': allExercises,
      };
    } catch (e) {
      debugPrint("Error loading routine info: $e");
      return {
        'totalTime': '0 min',
        'averageTime': '0 min',
        'allMuscles': [],
        'routineLevel': 'beginner',
        'allExercises': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final routineName = (widget.routine['rName']?.isNotEmpty == true)
        ? widget.routine['rName']
        : 'Unnamed Routine';
    final restTime = widget.routine['restTime']?.toString() ?? '30';
    final days = List<Map<String, dynamic>>.from(widget.routine["days"] ?? []);
    final routineInfoFuture = _getRoutineInfo(days, widget.routine["restTime"]);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        title: const Text(
          'Routine Details',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
            UpdateDock.updateSystemUI(Colors.white);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: routineInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const _InfoCard(
                  title: 'Error loading routine data',
                  content: 'Please try again later',
                );
              }

              final data = snapshot.data!;
              final allExercises = data['allExercises'] as List<dynamic>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoutineHeader(
                    name: routineName,
                    level: data['routineLevel'],
                    color: _getRoutineColor(routineName),
                    icon: _getRoutineIcon(routineName),
                  ),
                  const SizedBox(height: 20),
                  _InfoGrid(
                    restTime: '$restTime sec',
                    averageTime: data['averageTime'],
                    muscles: data['allMuscles'].join(', '),
                  ),
                  const SizedBox(height: 24),
                  _WeekdaysSelector(
                    weekdaysShort: _weekdaysShort,
                    selectedDays: _selectedDays,
                  ),
                  const SizedBox(height: 24),
                  ..._buildDayWidgets(allExercises),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getRoutineColor(String name) {
    final index = name.length % _routineColors.length;
    return _routineColors[index];
  }

  IconData _getRoutineIcon(String name) {
    final index = name.length % _routineIcons.length;
    return _routineIcons[index];
  }

  List<Widget> _buildDayWidgets(List<dynamic> allExercises) {
    List<Widget> dayWidgets = [];

    for (int dayIndex = 0; dayIndex < _selectedDays.length; dayIndex++) {
      if (!_selectedDays[dayIndex]) continue;

      final dayData = _exercisesByDay[dayIndex];
      if (dayData == null) continue;

      dayWidgets.add(
        _DayExercises(
          dayIndex: dayIndex,
          weekDay: _weekdaysFull[dayIndex],
          dayName: dayData['dayName'],
          exercises: dayData['exercises'],
          allExercises: allExercises,
        ),
      );
      dayWidgets.add(const SizedBox(height: 20));
    }

    return dayWidgets;
  }
}

class _RoutineHeader extends StatelessWidget {
  final String name;
  final String level;
  final Color color;
  final IconData icon;

  const _RoutineHeader({
    required this.name,
    required this.level,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              level[0].toUpperCase() + level.substring(1),
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final String restTime;
  final String averageTime;
  final String muscles;

  const _InfoGrid({
    required this.restTime,
    required this.averageTime,
    required this.muscles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.timer,
                title: 'Rest Time',
                value: restTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.schedule,
                title: 'Avg. Duration',
                value: averageTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.fitness_center,
          title: 'Muscles Worked',
          value: muscles,
          span: true,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool span;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.span = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: span ? double.infinity : null,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFA90015), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
              maxLines: span ? 4 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdaysSelector extends StatelessWidget {
  final List<String> weekdaysShort;
  final List<bool> selectedDays;

  const _WeekdaysSelector({
    required this.weekdaysShort,
    required this.selectedDays,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'Training Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(weekdaysShort.length, (index) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedDays[index] ? Color(0xFFA90015) : Colors.white,
                  border: Border.all(
                    color: selectedDays[index] ? Color(0xFFA90015) : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    weekdaysShort[index],
                    style: TextStyle(
                      color: selectedDays[index] ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DayExercises extends StatelessWidget {
  final int dayIndex;
  final String dayName;
  final List<Map<String, dynamic>> exercises;
  final String weekDay;
  final List<dynamic> allExercises;

  const _DayExercises({
    required this.dayIndex,
    required this.dayName,
    required this.exercises,
    required this.weekDay,
    required this.allExercises,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            '$weekDay - $dayName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No exercises for this day',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ...exercises.map((exercise) => _ExerciseItem(
                    name: exercise['name'],
                    reps: exercise['reps'],
                    duration: exercise['duration'],
                    series: exercise['series'],
                    exerciseId: exercise['id'],
                    allExercises: allExercises,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseItem extends StatelessWidget {
  final String name;
  final int? reps;
  final int? duration;
  final int series;
  final String exerciseId;
  final List<dynamic> allExercises;

  const _ExerciseItem({
    required this.name,
    required this.reps,
    required this.duration,
    required this.series,
    required this.exerciseId,
    required this.allExercises,
  });

  String _getExerciseLevel() {
    final exercise = allExercises.firstWhere(
      (ex) => ex["id"] == exerciseId,
      orElse: () => {"level": "beginner"},
    );
    return exercise["level"]?.toString().toLowerCase() ?? "beginner";
  }

  Color _getBorderColor(String level) {
    switch (level.toLowerCase()) {
      case 'intermediate':
        return Colors.amber;
      case 'expert':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _getMuscleImage() {
    final exercise = allExercises.firstWhere(
      (ex) => ex["id"] == exerciseId,
      orElse: () => {"primaryMuscles": []},
    );
    
    if (exercise["primaryMuscles"] is List && exercise["primaryMuscles"].isNotEmpty) {
      final primaryMuscle = exercise["primaryMuscles"][0];
      return primaryMuscle.toString().toLowerCase().replaceAll(' ', '_');
    }
    return 'default';
  }

  @override
  Widget build(BuildContext context) {
    final level = _getExerciseLevel();
    final imagePath = 'assets/muscle_images/${_getMuscleImage()}.png';
    
    // Determinar qué texto mostrar
    final repsText = duration != null 
      ? '${duration}s × $series' 
      : '${reps ?? 0} × $series';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getBorderColor(level),
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.fitness_center,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFA90015).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                repsText,
                style: TextStyle(
                  color: Color(0xFFA90015),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _InfoCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}