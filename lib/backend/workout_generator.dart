
import 'package:muscle_app/backend/exercise_loader.dart';

Future<Map<String, dynamic>> generateRoutine({
  required String level,
  required String goal,
  required List<bool> selectedDays,
  required double sliderValue,
}) async {
  switch((goal)){
    case "Improve health":
      return await _selectExercisesForHealth(selectedDays: selectedDays, level: level, sliderValue: sliderValue);
    case "Increase strength":
      return await _selectExercisesForStrength(selectedDays: selectedDays, level: level, sliderValue: sliderValue);
    default:
      return await _selectExercisesForPhysique(selectedDays: selectedDays, level: level, sliderValue: sliderValue); 
  }
}

int _estimateMinutes(double sliderValue) {
  switch (sliderValue.round()) {
    case 1:
      return 30;
    case 2:
      return 45;
    case 3:
      return 75;
    case 4:
      return 105;
    case 5:
      return 130;
    default:
      return 45;
  }
}

String _dayName(int index) {
  const dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  return dayNames[index];
}

//Health functions
Future<Map<String, dynamic>> _selectExercisesForHealth({
  required List<bool> selectedDays,
  required String level,
  required double sliderValue,
}) async {
  final allExercises = await ExerciseLoader.importExercisesDetails();
  final minutesPerSession = _estimateMinutes(sliderValue);

  final cardioExercises = allExercises.where((e) {
    bool isValidLevel = false;
    if (level == "Beginner") {
      isValidLevel = e["level"] == "beginner";
    } else if (level == "Intermediate") {
      isValidLevel = e["level"] == "beginner" || e["level"] == "intermediate";
    } else if (level == "Expert") {
      isValidLevel = e["level"] == "beginner" || e["level"] == "intermediate" || e["level"] == "expert";
    }
    return (e["category"]?.toLowerCase() == "cardio") && isValidLevel;
  }).toList();

  final strengthExercises = allExercises.where((e) {
    bool isValidLevel = false;
    if (level == "Beginner") {
      isValidLevel = e["level"] == "beginner";
    } else if (level == "Intermediate") {
      isValidLevel = e["level"] == "beginner" || e["level"] == "intermediate";
    } else if (level == "Expert") {
      isValidLevel = e["level"] == "beginner" || e["level"] == "intermediate" || e["level"] == "expert";
    }
    return (e["category"] == 'strength' || e["category"] == 'powerlifting') && isValidLevel;
  }).toList();

  final routine = <Map<String, dynamic>>[];
  final trainingDaysIndices = selectedDays.asMap().entries.where((entry) => entry.value).map((entry) => entry.key).toList();
  final trainingDaysCount = trainingDaysIndices.length;
  final maxStrengthDays = trainingDaysCount >= 3 ? 3 : 2;
  final strengthDaysToAssignIndices = _distributeStrengthDays(trainingDaysIndices, maxStrengthDays);
  final assignedStrengthDaysSet = strengthDaysToAssignIndices.toSet();
  final int restTime = 60;

  print("Cardio: ${cardioExercises.length}");
  print("Strength: ${strengthExercises.length}");
  print("Días de entrenamiento seleccionados (índices): $trainingDaysIndices");
  print("Días de fuerza a asignar (índices): $strengthDaysToAssignIndices");

  Set<String> lastDayMuscles = {}; // Para rastrear los músculos del día anterior

  for (int i = 0; i < 7; i++) {
    if (selectedDays[i]) {
      final dayName = _dayName(i);
      final isStrengthDay = assignedStrengthDaysSet.contains(i);

      print("\n--- Procesando día: $dayName (¿Fuerza?: $isStrengthDay) ---");
      print("Músculos del día anterior: $lastDayMuscles");

      final dailyExercises = _selectExercisesForHealthDay(
        strengthExercises: strengthExercises,
        cardioExercises: cardioExercises,
        level: level,
        duration: minutesPerSession,
        isStrengthDay: isStrengthDay,
        excludedMuscles: lastDayMuscles, // Pasamos los músculos del día anterior
      );

      routine.add({
        "dayName": dayName,
        "weekDay": dayName,
        "exercises": dailyExercises,
      });

      print("Ejercicios para el día: $dailyExercises");

      // Actualizamos los músculos trabajados en el día actual para la siguiente iteración
      lastDayMuscles = dailyExercises
          .where((exercise) => exercise.containsKey("primaryMuscles"))
          .expand((exercise) => (exercise["primaryMuscles"] as List<dynamic>).map((m) => m.toString().toLowerCase()).toSet())
          .toSet();

      print("Músculos trabajados en este día: $lastDayMuscles");

    } else {
      // Si no es un día de entrenamiento, reiniciamos el rastreo de músculos
      lastDayMuscles = {};
      print("\n--- Día de descanso ---");
      print("Músculos del día anterior reiniciados: $lastDayMuscles");
    }
  }

  return {
    "restTime": restTime,
    "level": level,
    "rName": "Health Focused     ",
    "creatorId": "MuscleApp",
    "days": routine,
  };
}

List<Map<String, dynamic>> _selectExercisesForHealthDay({
  required List<dynamic> strengthExercises,
  required List<dynamic> cardioExercises,
  required String level,
  required int duration,
  required bool isStrengthDay,
  Set<String>? excludedMuscles, // Nuevo parámetro para los músculos excluidos
}) {
  final List<Map<String, dynamic>> selection = [];
  int remainingTime = duration;
  final musclesTargeted = <String>{}; // Para rastrear los grupos musculares ya incluidos

  // 1. Cardio principal
  if (cardioExercises.isNotEmpty) {
    cardioExercises.shuffle();
    final cardio = cardioExercises.first;
    selection.add({
      "exerciseName": cardio["name"],
      "exerciseID": cardio["id"],
      "duration": 1140,
      "series": 1
    });
    remainingTime -= 25;
  }

  // 2. Fuerza, si toca en este día y hay tiempo
  if (isStrengthDay && remainingTime >= 5) {
    final availableExercises = List<Map<String, dynamic>>.from(strengthExercises);
    availableExercises.shuffle(); // Para variar la selección inicial

    print("Músculos excluidos para este día: $excludedMuscles");
    const musclePriority = ["quadriceps", "chest", "lats", "middle_back", "biceps", "triceps", "hamstrings", "shoulders"];
    for (final muscleGroup in musclePriority) {
      if (remainingTime < _estimateStrengthExerciseDuration()) break;

      print("Intentando seleccionar ejercicio para el grupo muscular: $muscleGroup");

      final eligibleExercise = availableExercises.firstWhere(
        (e) => (e["primaryMuscles"] as List<dynamic>?)?.any((m) => m.toString().toLowerCase() == muscleGroup) == true &&
                 !musclesTargeted.contains(muscleGroup) &&
                 !(excludedMuscles?.contains(muscleGroup) ?? false), // Comprobamos si el músculo está excluido
        orElse: () => {},
      );

      if (eligibleExercise.isNotEmpty) {
        print("Ejercicio elegible encontrado: ${eligibleExercise["name"]} (Músculos primarios: ${eligibleExercise["primaryMuscles"]})");
        selection.add({
          "exerciseName": eligibleExercise["name"],
          "exerciseID": eligibleExercise["id"],
          "reps": 10,
          "series": 3,
          "lastWeight": 0,
          "primaryMuscles": eligibleExercise["primaryMuscles"] // Añadimos los músculos primarios al ejercicio seleccionado para facilitar la depuración
        });
        musclesTargeted.add(muscleGroup);
        availableExercises.remove(eligibleExercise); // Para no volver a seleccionar el mismo ejercicio
        remainingTime -= _estimateStrengthExerciseDuration();
      } else {
        print("No se encontró un ejercicio elegible para el grupo muscular: $muscleGroup");
      }
    }

    // Añadir ejercicios restantes si hay tiempo
    while (remainingTime >= _estimateStrengthExerciseDuration() && availableExercises.isNotEmpty) {
      final exercise = availableExercises.first;
      // Aquí podríamos añadir una lógica similar para evitar repetir músculos incluso en los ejercicios adicionales
      selection.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"],
        "reps": 10,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": exercise["primaryMuscles"] // Añadimos los músculos primarios
      });
      availableExercises.remove(exercise);
      remainingTime -= _estimateStrengthExerciseDuration();
    }
  }

  return selection;
}

List<int> _distributeStrengthDays(List<int> trainingDaysIndices, int numStrengthDays) {
  if (numStrengthDays >= trainingDaysIndices.length) {
    return trainingDaysIndices;
  }

  final strengthDays = <int>[];
  if (numStrengthDays == 1 && trainingDaysIndices.isNotEmpty) {
    strengthDays.add(trainingDaysIndices[trainingDaysIndices.length ~/ 2]);
  } else if (numStrengthDays == 2 && trainingDaysIndices.length >= 2) {
    strengthDays.add(trainingDaysIndices[0]);
    strengthDays.add(trainingDaysIndices[trainingDaysIndices.length - 1]);
  } else if (numStrengthDays == 3 && trainingDaysIndices.length >= 3) {
    strengthDays.add(trainingDaysIndices[0]);
    strengthDays.add(trainingDaysIndices[trainingDaysIndices.length ~/ 2]);
    strengthDays.add(trainingDaysIndices[trainingDaysIndices.length - 1]);
  }
  // Puedes extender esto para más días de fuerza si es necesario

  return strengthDays;
}

int _estimateStrengthExerciseDuration({int reps = 10, int series = 3, int restTime = 60}) {
  final totalSeconds = (reps * 5 * series) + (restTime * (series - 1));
  return ((totalSeconds / 60) * 1.8).ceil(); 
}

//Strength functions
Future<Map<String, dynamic>> _selectExercisesForStrength({
  required List<bool> selectedDays,
  required String level,
  required double sliderValue,
}) async {
  final allExercises = await ExerciseLoader.importExercisesDetails();
  final daysCount = selectedDays.where((e) => e).length;
  final minutesPerSession = _estimateMinutes(sliderValue);
  final restTime = 180;

  final Map<String, List<Map<String, dynamic>>> planByDay = {};

  // 🔎 Filtrar ejercicios por nivel
  final availableExercises = allExercises.where((e) {
    if (level == "Beginner") return e["level"] == "beginner";
    if (level == "Intermediate") return e["level"] != "expert";
    return true;
  }).toList();

  int dayCounter = 0;

for (int i = 0; i < 7; i++) {
  if (selectedDays[i]) {
    final String dayName = _dayName(i);

    List<Map<String, dynamic>> exercises;

    switch (daysCount) {
      case 1:
        exercises = _generateFullBodyStrengthDay(availableExercises, minutesPerSession);
        break;

      case 2:
        exercises = (dayCounter == 0)
            ? _generateUpperBodyDay(availableExercises, minutesPerSession)
            : _generateLowerBodyDay(availableExercises, minutesPerSession);
        break;

      case 3:
        if (dayCounter == 0) {
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generateLegDay(availableExercises, minutesPerSession);
        }
        break;

      case 4:
        if (dayCounter == 0 || dayCounter == 2) {
          exercises = _generateUpperBodyDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generateLowerBodyDay(availableExercises, minutesPerSession);
        }
        break;

      case 5:
        if (dayCounter == 0) {
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 2) {
          exercises = _generateLegDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 3){
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        }
        break;

      case 6:
        if (dayCounter == 0) {
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 2) {
          exercises = _generateLegDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 3) {
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 4) {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generateLegDay(availableExercises, minutesPerSession);
        }
        break;

      default:
        if (dayCounter == 0) {
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 2) {
          exercises = _generateLegDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 3) {
          exercises = _generateCardioDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 4) {
          exercises = _generatePushDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 5) {
          exercises = _generatePullDay(availableExercises, minutesPerSession);
        } else { // dayCounter == 6
          exercises = _generateLegDay(availableExercises, minutesPerSession);
        }
        break;
    }

    planByDay[dayName] = exercises;
    dayCounter++;
  }
}

  // 🧱 Construcción del objeto de rutina
  final routine = planByDay.entries.map((entry) => {
    "dayName": entry.key,
    "weekDay": entry.key,
    "exercises": entry.value,
  }).toList();

  return {
    "restTime": restTime,
    "level": level,
    "rName": "Strength Focused",
    "creatorId": "MuscleApp",
    "days": routine,
  };
}

List<Map<String, dynamic>> _generateFullBodyStrengthDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  const targetGroups = {
    "legs": ["quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors"],
    "back": ["lats", "middle back", "lower back", "traps"],
    "chest": ["chest"],
    "arms": ["biceps", "triceps", "forearms"],
    "shoulders": ["shoulders"],
    "core": ["abdominals"],
  };

  int remainingTime = minutesPerSession;
  const int exerciseTime = 15;

  // Ejercicios compuestos y mezclados
  final compoundExercises = allExercises.where((e) {
    return (e["mechanic"]?.toString().toLowerCase() == "compound");
  }).toList();

  compoundExercises.shuffle(); // para variabilidad

  final selected = <Map<String, dynamic>>[];
  final usedGroups = <String>{};

  for (final exercise in compoundExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    String? groupMatched;
    for (final group in targetGroups.entries) {
      if (primaryMuscles.any((m) => group.value.contains(m))) {
        groupMatched = group.key;
        break;
      }
    }

    if (groupMatched != null && !usedGroups.contains(groupMatched)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 10,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedGroups.add(groupMatched);
      remainingTime -= exerciseTime;
    }
  }

  // Rellenamos si sobra tiempo (aunque repita grupos)
  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(compoundExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 10,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  return selected;
}

List<Map<String, dynamic>> _generatePushDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> pushMuscles = ["chest", "shoulders", "triceps"];
  int exerciseTime = ((5*5*3+3*180)/60).ceil();
  int remainingTime = minutesPerSession;

  // Solo ejercicios compuestos que afectan músculos de empuje
  final pushExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => pushMuscles.contains(m));
  }).toList();

  pushExercises.shuffle(); // Para variedad

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in pushExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    // Evita repetir músculos hasta que sea necesario
    final targetMuscle = primaryMuscles.firstWhere(
      (m) => pushMuscles.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 4,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  // Rellenar si queda tiempo
  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(pushExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 4,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  return selected;
}

List<Map<String, dynamic>> _generatePullDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> pullMuscles = [
    "lats",
    "middle back",
    "lower back",
    "biceps",
    "forearms",
  ];
  int exerciseTime = ((5*5*3+3*180)/60).ceil();
  int remainingTime = minutesPerSession;

  final pullExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => pullMuscles.contains(m));
  }).toList();

  pullExercises.shuffle();

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in pullExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    final targetMuscle = primaryMuscles.firstWhere(
      (m) => pullMuscles.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 4,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  // Rellenar si queda tiempo
  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(pullExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 4,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  return selected;
}

List<Map<String, dynamic>> _generateLegDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> legMuscles = [
    "quadriceps",
    "hamstrings",
    "glutes",
    "calves",
    "adductors",
    "abductors",
  ];
  int exerciseTime = ((5*5*3+3*180)/60).ceil();
  int remainingTime = minutesPerSession;

  final legExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => legMuscles.contains(m));
  }).toList();

  legExercises.shuffle();

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in legExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    final targetMuscle = primaryMuscles.firstWhere(
      (m) => legMuscles.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 5,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  // Rellenar si queda tiempo
  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(legExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 6,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  return selected;
}

List<Map<String, dynamic>> _generateUpperBodyDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> upperMuscleGroups = [
    "chest", "lats", "middle back", "lower back", "shoulders",
    "biceps", "triceps", "traps", "forearms", "neck"
  ];
  int exerciseTime = ((5*5*3+3*180)/60).ceil();
  int remainingTime = minutesPerSession;

  final upperBodyExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => upperMuscleGroups.contains(m));
  }).toList();

  upperBodyExercises.shuffle();

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in upperBodyExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    final targetMuscle = primaryMuscles.firstWhere(
      (m) => upperMuscleGroups.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 5,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  // Rellenar si queda tiempo
  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(upperBodyExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 6,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  return selected;
}

List<Map<String, dynamic>> _generateLowerBodyDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> lowerBodyMuscleGroups = [
    "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors"
  ];
  int exerciseTime = ((5*5*3+3*180)/60).ceil();
  int remainingTime = minutesPerSession;

  final lowerBodyExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => lowerBodyMuscleGroups.contains(m));
  }).toList();

  lowerBodyExercises.shuffle();

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in lowerBodyExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    final targetMuscle = primaryMuscles.firstWhere(
      (m) => lowerBodyMuscleGroups.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 5,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  // Rellenar si queda tiempo
  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(lowerBodyExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 6,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  return selected;
}

List<Map<String, dynamic>> _generateCardioDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  // Filtrar ejercicios de tipo "cardio"
  final cardioExercises = allExercises.where((e) =>
    e["category"]?.toLowerCase() == "cardio"
  ).toList();

  // Aleatorizar para elegir uno al azar
  cardioExercises.shuffle();

  // Seleccionar el primer ejercicio de cardio si existe
  if (cardioExercises.isEmpty) {
    return [];
  }

  final Map<String, dynamic> selectedCardio = cardioExercises.first;

  return [
    {
      "exerciseName": selectedCardio["name"],
      "exerciseID": selectedCardio["id"] ?? selectedCardio["name"].toString().replaceAll(" ", "_"),
      "duration": 1140,
      "series": 1,
      "lastWeight": 0,
      "primaryMuscles": (selectedCardio["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ?? [],
    }
  ];
}

//Physique functions
Future<Map<String, dynamic>> _selectExercisesForPhysique({
  required List<bool> selectedDays,
  required String level,
  required double sliderValue,
}) async {
  final allExercises = await ExerciseLoader.importExercisesDetails();
  final daysCount = selectedDays.where((e) => e).length;
  final minutesPerSession = _estimateMinutes(sliderValue);
  final restTime = 150;

  final Map<String, List<Map<String, dynamic>>> planByDay = {};

  // 🔎 Filtrar ejercicios por nivel
  final availableExercises = allExercises.where((e) {
    if (level == "Beginner") return e["level"] == "beginner";
    if (level == "Intermediate") return e["level"] != "expert";
    return true;
  }).toList();

  int dayCounter = 0;

for (int i = 0; i < 7; i++) {
  if (selectedDays[i]) {
    final String dayName = _dayName(i);

    List<Map<String, dynamic>> exercises;

    switch (daysCount) {
      case 1:
        exercises = _generateFullBodyPhysiqueDay(availableExercises, minutesPerSession);
        break;

      case 2:
        exercises = (dayCounter == 0)
            ? _generateUpperBodyPhysiqueDay(availableExercises, minutesPerSession)
            : _generateLowerBodyPhysiqueDay(availableExercises, minutesPerSession);
        break;

      case 3:
        if (dayCounter == 0) {
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generateLegPhysiqueDay(availableExercises, minutesPerSession);
        }
        break;

      case 4:
        if (dayCounter == 0 || dayCounter == 2) {
          exercises = _generateUpperBodyDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generateLowerBodyDay(availableExercises, minutesPerSession);
        }
        break;

      case 5:
        if (dayCounter == 0) {
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 2) {
          exercises = _generateLegPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 3){
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        }
        break;

      case 6:
        if (dayCounter == 0) {
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 2) {
          exercises = _generateLegPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 3) {
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 4) {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        } else {
          exercises = _generateLegPhysiqueDay(availableExercises, minutesPerSession);
        }
        break;

      default:
        if (dayCounter == 0) {
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 1) {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 2) {
          exercises = _generateLegPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 3) {
          exercises = _generateCardioDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 4) {
          exercises = _generatePushPhysiqueDay(availableExercises, minutesPerSession);
        } else if (dayCounter == 5) {
          exercises = _generatePullPhysiqueDay(availableExercises, minutesPerSession);
        } else { // dayCounter == 6
          exercises = _generateLegPhysiqueDay(availableExercises, minutesPerSession);
        }
        break;
    }

    planByDay[dayName] = exercises;
    dayCounter++;
  }
}

  // 🧱 Construcción del objeto de rutina
  final routine = planByDay.entries.map((entry) => {
    "dayName": entry.key,
    "weekDay": entry.key,
    "exercises": entry.value,
  }).toList();

  return {
    "restTime": restTime,
    "level": level,
    "rName": "Physique Focused",
    "creatorId": "MuscleApp",
    "days": routine,
  };
}

List<Map<String, dynamic>> _generateFullBodyPhysiqueDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  const targetGroups = {
    "legs": ["quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors"],
    "back": ["lats", "middle back", "lower back", "traps"],
    "chest": ["chest"],
    "arms": ["biceps", "triceps", "forearms"],
    "shoulders": ["shoulders"],
    "core": ["abdominals"],
  };

  int remainingTime = minutesPerSession - 15; // Reserve 15 minutes for cardio
  const int exerciseTime = 15;

  final compoundExercises = allExercises.where((e) {
    return (e["mechanic"]?.toString().toLowerCase() == "compound");
  }).toList();

  compoundExercises.shuffle();

  final selected = <Map<String, dynamic>>[];
  final usedGroups = <String>{};

  for (final exercise in compoundExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    String? groupMatched;
    for (final group in targetGroups.entries) {
      if (primaryMuscles.any((m) => group.value.contains(m))) {
        groupMatched = group.key;
        break;
      }
    }

    if (groupMatched != null && !usedGroups.contains(groupMatched)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
      });
      usedGroups.add(groupMatched);
      remainingTime -= exerciseTime;
    }
  }

  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(compoundExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ??
          [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  // Añadir siempre un ejercicio de cardio al final
  selected.add({
    "exerciseName": "Cardio",
    "exerciseID": "cardio_finish",
    "duration": 900,
    "series": 1,
    "lastWeight": 0,
  });

  return selected;
}

List<Map<String, dynamic>> _generateUpperBodyPhysiqueDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> upperMuscleGroups = [
    "chest", "lats", "middle back", "lower back", "shoulders",
    "biceps", "triceps", "traps", "forearms", "neck"
  ];
  int exerciseTime = ((5 * 5 * 3 + 3 * 180) / 60).ceil();
  int remainingTime = minutesPerSession - 15; // Reserve 15 minutes for cardio

  final upperBodyExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => upperMuscleGroups.contains(m));
  }).toList();

  upperBodyExercises.shuffle();

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in upperBodyExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    final targetMuscle = primaryMuscles.firstWhere(
      (m) => upperMuscleGroups.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(upperBodyExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;


      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
      });
      remainingTime -= exerciseTime;
    }
  }
  selected.add({
    "exerciseName": "Walking, Treadmill",
    "exerciseID": "Walking_Treadmill",
    "duration": 900,
    "series": 1,
    "lastWeight": 0,
  });

  return selected;
}

List<Map<String, dynamic>> _generateLowerBodyPhysiqueDay(
  List<Map<String, dynamic>> allExercises,
  int minutesPerSession,
) {
  final List<String> lowerBodyMuscleGroups = [
    "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors"
  ];
  int exerciseTime = ((5 * 5 * 3 + 3 * 180) / 60).ceil();
  int remainingTime = minutesPerSession - 15; // Reserve 15 minutes for cardio

  final lowerBodyExercises = allExercises.where((e) {
    final mechanic = e["mechanic"]?.toString().toLowerCase();
    final List<String> muscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];
    return mechanic == "compound" &&
        muscles.any((m) => lowerBodyMuscleGroups.contains(m));
  }).toList();

  lowerBodyExercises.shuffle();

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscles = {};

  for (final exercise in lowerBodyExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ??
        [];

    final targetMuscle = primaryMuscles.firstWhere(
      (m) => lowerBodyMuscleGroups.contains(m),
      orElse: () => "",
    );

    if (targetMuscle.isNotEmpty && !usedMuscles.contains(targetMuscle)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,

      });
      usedMuscles.add(targetMuscle);
      remainingTime -= exerciseTime;
    }
  }

  if (remainingTime >= exerciseTime) {
    final remainingPool = List<Map<String, dynamic>>.from(lowerBodyExercises)
      ..removeWhere((e) => selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_"))));

    remainingPool.shuffle();

    for (final exercise in remainingPool) {
      if (remainingTime < exerciseTime) break;

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
      });
      remainingTime -= exerciseTime;
    }
  }

  // Añadir siempre un ejercicio de cardio al final
  selected.add({
    "exerciseName": "Walking, Treadmill",
    "exerciseID": "Walking_Treadmill",
    "duration": 900,
    "series": 1,
    "lastWeight": 0,
  });

  return selected;
}

List<Map<String, dynamic>> _generatePushPhysiqueDay(
  List<Map<String, dynamic>> availableExercises,
  int minutesPerSession,
) {
  int remainingTime = minutesPerSession - 15; // Reserve 15 minutes for cardio
  const int exerciseTime = 15; // Assuming each exercise takes around 15 minutes

  // Filter compound push exercises (chest, shoulders, triceps)
  final pushExercises = availableExercises.where((e) {
    final List<String> primaryMuscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ?? [];
    return e["mechanic"]?.toString().toLowerCase() == "compound" &&
        primaryMuscles.any((m) => ["chest", "shoulders", "triceps"].contains(m));
  }).toList();

  // Sort by number of secondary muscles (more = more global/more effective)
  pushExercises.sort((a, b) {
    final aSec = (a["secondaryMuscles"] as List?)?.length ?? 0;
    final bSec = (b["secondaryMuscles"] as List?)?.length ?? 0;
    return bSec.compareTo(aSec);
  });

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscleGroups = {};

  for (final exercise in pushExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ?? [];

    // Prioritize different muscle groups
    String? primaryGroup;
    if (primaryMuscles.contains("chest")) {
      primaryGroup = "chest";
    } else if (primaryMuscles.contains("shoulders")) {
      primaryGroup = "shoulders";
    } else if (primaryMuscles.contains("triceps")) {
      primaryGroup = "triceps";
    }

    // Add exercise if we haven't maxed out this muscle group yet
    if (primaryGroup != null && (usedMuscleGroups.length < 3 || !usedMuscleGroups.contains(primaryGroup))) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8, // Default values matching other methods
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscleGroups.add(primaryGroup);
      remainingTime -= exerciseTime;
    }

    if (selected.length >= 6) break; // Limiting to a reasonable number of exercises
  }

  // Add cardio at the end
  selected.add({
    "exerciseName": "Walking, Treadmill",
    "exerciseID": "Walking_Treadmill",
    "duration": 900,
    "series": 1,
    "lastWeight": 0,
    "primaryMuscles": ["cardiovascular"],
  });

  return selected;
}

List<Map<String, dynamic>> _generatePullPhysiqueDay(
  List<Map<String, dynamic>> availableExercises,
  int minutesPerSession,
) {
  int remainingTime = minutesPerSession - 15; // Reserve 15 minutes for cardio
  const int exerciseTime = 15; // Assuming each exercise takes around 15 minutes

  // Filter compound pull exercises (back, biceps)
  final pullExercises = availableExercises.where((e) {
    final List<String> primaryMuscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ?? [];
    return e["mechanic"]?.toString().toLowerCase() == "compound" &&
        primaryMuscles.any((m) => ["lats", "middle back", "lower back", "biceps"].contains(m));
  }).toList();

  // Sort by number of secondary muscles (more = more global/more effective)
  pullExercises.sort((a, b) {
    final aSec = (a["secondaryMuscles"] as List?)?.length ?? 0;
    final bSec = (b["secondaryMuscles"] as List?)?.length ?? 0;
    return bSec.compareTo(aSec);
  });

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedBackSubgroups = {};
  bool hasBicepsExercise = false;

  for (final exercise in pullExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ?? [];

    // Identify back subgroups and biceps focus
    String? backSubgroup;
    if (primaryMuscles.contains("lats")) {
      backSubgroup = "lats";
    } else if (primaryMuscles.contains("middle back")) {
      backSubgroup = "middle back";
    } else if (primaryMuscles.contains("lower back")) {
      backSubgroup = "lower back";
    }

    final bool isBicepsFocused = primaryMuscles.contains("biceps") &&
        !primaryMuscles.any((m) => ["lats", "middle back", "lower back"].contains(m));

    // Selection logic
    if (backSubgroup != null && !usedBackSubgroups.contains(backSubgroup)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedBackSubgroups.add(backSubgroup);
      remainingTime -= exerciseTime;
    } else if (!hasBicepsExercise && isBicepsFocused) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      hasBicepsExercise = true;
      remainingTime -= exerciseTime;
    }

    if (selected.length >= 6) break; // Limiting to a reasonable number of exercises
  }

  // If we have space left, add more back exercises
  if (selected.length < 6) {
    final remainingExercises = pullExercises.where((e) =>
        !selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_")))
    ).toList();

    for (final exercise in remainingExercises.take(6 - selected.length)) {
      if (remainingTime < exerciseTime) break;
      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ?? [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  // Add cardio at the end
  selected.add({
    "exerciseName": "Walking, Treadmill",
    "exerciseID": "Walking_Treadmill",
    "duration": 900,
    "series": 1,
    "lastWeight": 0,
    "primaryMuscles": ["cardiovascular"],
  });

  return selected;
}

List<Map<String, dynamic>> _generateLegPhysiqueDay(
  List<Map<String, dynamic>> availableExercises,
  int minutesPerSession,
) {
  int remainingTime = minutesPerSession - 15; // Reserve 15 minutes for cardio
  const int exerciseTime = 15; // Assuming each exercise takes around 15 minutes

  // Number of exercises based on time (4-8 exercises)
  final int maxExercises = 6;

  // Filter compound leg exercises
  final legExercises = availableExercises.where((e) {
    final List<String> primaryMuscles = (e["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ?? [];
    return e["mechanic"]?.toString().toLowerCase() == "compound" &&
        primaryMuscles.any((m) => ["quadriceps", "hamstrings", "glutes"].contains(m));
  }).toList();

  // Sort by number of secondary muscles (more = more global/more effective)
  legExercises.sort((a, b) {
    final aSec = (a["secondaryMuscles"] as List?)?.length ?? 0;
    final bSec = (b["secondaryMuscles"] as List?)?.length ?? 0;
    return bSec.compareTo(aSec);
  });

  final List<Map<String, dynamic>> selected = [];
  final Set<String> usedMuscleGroups = {};

  for (final exercise in legExercises) {
    if (remainingTime < exerciseTime) break;

    final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
            ?.map((m) => m.toString().toLowerCase())
            .toList() ?? [];

    // Identify specific muscle focus
    String? muscleFocus;
    if (primaryMuscles.contains("quadriceps") &&
        !primaryMuscles.contains("hamstrings")) {
      muscleFocus = "quad-dominant";
    } else if (primaryMuscles.contains("hamstrings") &&
        !primaryMuscles.contains("quadriceps")) {
      muscleFocus = "hamstring-dominant";
    } else if (primaryMuscles.contains("glutes") &&
        !primaryMuscles.contains("quadriceps")) {
      muscleFocus = "glute-dominant";
    } else {
      muscleFocus = "compound-leg";
    }

    // Add exercise if we're not duplicating focus areas
    if (!usedMuscleGroups.contains(muscleFocus)) {
      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8, // Default values matching other methods
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      usedMuscleGroups.add(muscleFocus);
      remainingTime -= exerciseTime;
    }

    if (selected.length >= maxExercises) break;
  }

  // If we have space left, add more leg exercises
  if (selected.length < maxExercises) {
    final remainingExercises = legExercises.where((e) =>
        !selected.any((s) => s["exerciseID"] == (e["id"] ?? e["name"].toString().replaceAll(" ", "_")))
    ).toList();

    for (final exercise in remainingExercises.take(maxExercises - selected.length)) {
      if (remainingTime < exerciseTime) break;
      final List<String> primaryMuscles = (exercise["primaryMuscles"] as List?)
              ?.map((m) => m.toString().toLowerCase())
              .toList() ?? [];

      selected.add({
        "exerciseName": exercise["name"],
        "exerciseID": exercise["id"] ?? exercise["name"].toString().replaceAll(" ", "_"),
        "reps": 8,
        "series": 3,
        "lastWeight": 0,
        "primaryMuscles": primaryMuscles,
      });
      remainingTime -= exerciseTime;
    }
  }

  // Add cardio at the end
  selected.add({
    "exerciseName": "Walking, Treadmill",
    "exerciseID": "Walking_Treadmill",
    "duration": 900,
    "series": 1,
    "lastWeight": 0,
    "primaryMuscles": ["cardiovascular"],
  });

  return selected;
}