import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscle_app/backend/exercise_loader.dart';
import 'package:muscle_app/backend/achievement_manager.dart';

enum RoutineType { 
  fullBody,
  upperBody,
  lowerBody,
  pushPullLegs,
  upperLower,
  bodyPart,
  cardio
}

extension RoutineTypeExtension on RoutineType {
  String get displayName {
    switch (this) {
      case RoutineType.fullBody:
        return 'FULL BODY';
      case RoutineType.upperBody:
        return 'UPPER BODY';
      case RoutineType.lowerBody:
        return 'LOWER BODY';
      case RoutineType.pushPullLegs:
        return 'PUSH PULL LEGS';
      case RoutineType.upperLower:
        return 'UPPER/LOWER';
      case RoutineType.bodyPart:
        return 'BODY PART SPLIT';
      case RoutineType.cardio:
        return 'CARDIO';
    }
  }
}

class MarketplaceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> _getExerciseDetails(String exerciseId) async {
    final exercises = await ExerciseLoader.importExercisesDetails();
    return exercises.firstWhere(
      (exercise) => exercise['id'] == exerciseId,
      orElse: () => {},
    );
  }

  static Future<Set<String>> _getAllMusclesForExercise(String exerciseId) async {
    final exerciseDetails = await _getExerciseDetails(exerciseId);
    Set<String> muscles = {};
    
    if (exerciseDetails != null) {
      if (exerciseDetails['primaryMuscles'] != null) {
        muscles.addAll(List<String>.from(exerciseDetails['primaryMuscles']));
      }
      if (exerciseDetails['secondaryMuscles'] != null) {
        muscles.addAll(List<String>.from(exerciseDetails['secondaryMuscles']));
      }
    }
    
    return muscles;
  }

  static Future<bool> saveRoutineToMarketplace({required Map<String, dynamic> routine}) async {
    print('Intentando guardar rutina en el marketplace...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      print('Error: Usuario no autenticado o anónimo.');
      throw Exception('Usuario no autenticado');
    }
    print('Usuario autenticado: ${user.uid}');
    print('Rutina a guardar: ${routine["creatorId"]}');
    if (user.uid != routine['creatorId'] && routine['creatorId'] != null) {
      // Si el creador de la rutina no es el usuario actual, no se puede guardar
      print('Error: El creador de la rutina no coincide con el usuario actual.');
      throw Exception('El creador de la rutina no coincide con el usuario actual');
    }

    if (routine['rName'] == "") {
      throw Exception('La rutina no tiene nombre');
    }

    final routineWithoutIsActive = Map<String, dynamic>.from(routine)..remove('isActive');

    final routineData = {
      ...routineWithoutIsActive,
      'creatorId': user.uid,
      'downloads': 0,
      'totalVotes': {},
      'averageRating': 0.0,
    };

    print('Datos de la rutina que se va a guardar: $routineData');

    await _firestore.collection('marketplace').doc(routineData['rID']).set(routineData);
    
    AchievementManager().unlockAchievement("share_routine");
    print('Rutina guardada correctamente.');
    return true;
  }

  static Future<List<Map<String, dynamic>>> getMarketplaceRoutines() async {
    print('Obteniendo rutinas del marketplace...');
    try {
      final snapshot = await _firestore.collection('marketplace').get();
      List<Map<String, dynamic>> routines = [];
      print("Total de rutinas obtenidas: ${snapshot.docs.length}");

      for (var doc in snapshot.docs) {
        if (doc.data().isEmpty) {
          print('Documento vacío, saltando...');
          continue;
        }
        final data = doc.data();
        print('Datos crudos de rutina obtenida: $data');

        String routineType = await _determineRoutineType(data['days']);
        print('Tipo de rutina determinado: $routineType');

        String routineLevel = await _determineRoutineLevel(data['days']);
        print('Nivel de rutina determinado: $routineLevel');

        routines.add({
          ...data,
          'type': routineType,
          'level': routineLevel,
        });
      }

      print('Rutinas procesadas: ${routines.length}');
      return routines;
    } catch (e) {
      print('Error al obtener rutinas del marketplace: $e');
      return [];
    }
  }

  static Future<String> _determineRoutineType(List<dynamic> days) async {
    Set<String> allMuscles = {};
    print('--- Determinando tipo de rutina ---');

    for (var day in days) {
      for (var exercise in day['exercises']) {
        final muscles = await _getAllMusclesForExercise(exercise['exerciseID']);
        allMuscles.addAll(muscles);
      }
    }

    print('Músculos trabajados en total (primarios y secundarios): $allMuscles');

    if (await _isPushPullLegs(days)) {
      print('Clasificado como PUSH PULL LEGS');
      return RoutineType.pushPullLegs.displayName;
    }

    if (await _isFullBody(days)) {
      print('Clasificado como FULL BODY');
      return RoutineType.fullBody.displayName;
    }

    if (await _isUpperLowerSplit(days)) {
      print('Clasificado como UPPER/LOWER');
      return RoutineType.upperLower.displayName;
    }

    if (await _isBodyPartSplit(days)) {
      print('Clasificado como BODY PART SPLIT');
      return RoutineType.bodyPart.displayName;
    }

    if (await _isCardioFocused(days)) {
      print('Clasificado como CARDIO');
      return RoutineType.cardio.displayName;
    }

    final upperMuscles = {'chest', 'shoulders', 'triceps', 'back', 'biceps', 'traps', 'lats'};
    final lowerMuscles = {'quadriceps', 'hamstrings', 'calves', 'glutes'};

    int upperCount = allMuscles.intersection(upperMuscles).length;
    int lowerCount = allMuscles.intersection(lowerMuscles).length;

    print('Cantidad de músculos superiores: $upperCount');
    print('Cantidad de músculos inferiores: $lowerCount');

    if (upperCount > lowerCount) {
      print('Clasificado como UPPER BODY');
      return RoutineType.upperBody.displayName;
    } else {
      print('Clasificado como LOWER BODY');
      return RoutineType.lowerBody.displayName;
    }
  }

  static Future<bool> _containsMostlyMuscles(List<dynamic> exercises, Set<String> targetMuscles) async {
    int targetMuscleCount = 0;
    int totalExercises = exercises.length;

    for (var exercise in exercises) {
      final muscles = await _getAllMusclesForExercise(exercise['exerciseID']);
      if (muscles.intersection(targetMuscles).isNotEmpty) {
        targetMuscleCount++;
      }
    }

    print('De $totalExercises ejercicios, $targetMuscleCount trabajan los músculos objetivo: $targetMuscles');
    return totalExercises == 0 ? false : targetMuscleCount / totalExercises > 0.6;
  }

  static Future<bool> _isPushPullLegs(List<dynamic> days) async {
    if (days.length != 6) return false;

    print('Analizando si es PUSH PULL LEGS...');

    final Map<String, Set<String>> muscleGroups = {
      'push': {'chest', 'shoulders', 'triceps'},
      'pull': {'back', 'biceps', 'traps', 'lats'},
      'legs': {'quadriceps', 'hamstrings', 'calves', 'glutes'},
    };

    Future<bool> checkMuscleGroup(List<dynamic> exercises, Set<String> muscleSet) async {
      int count = 0;
      for (var exercise in exercises) {
        final muscles = await _getAllMusclesForExercise(exercise['exerciseID']);
        if (muscles.intersection(muscleSet).isNotEmpty) {
          count++;
        }
      }
      return count >= (exercises.length / 2);
    }

    final List<List<String>> validCombinations = [
      ['push', 'pull', 'legs'],
      ['push', 'legs', 'pull'],
      ['pull', 'push', 'legs'],
      ['pull', 'legs', 'push'],
      ['legs', 'push', 'pull'],
      ['legs', 'pull', 'push'],
    ];

    for (var combination in validCombinations) {
      bool isValid = true;

      for (int i = 0; i < 3; i++) {
        if (!await checkMuscleGroup(days[i]['exercises'], muscleGroups[combination[i]]!)) {
          isValid = false;
          break;
        }
      }

      if (isValid) {
        for (int i = 3; i < 6; i++) {
          if (!await checkMuscleGroup(days[i]['exercises'], muscleGroups[combination[i - 3]]!)) {
            isValid = false;
            break;
          }
        }
      }

      if (isValid) {
        print('¿Es PUSH PULL LEGS?: true');
        return true;
      }
    }

    print('¿Es PUSH PULL LEGS?: false');
    return false;
  }

  static Future<bool> _isFullBody(List<dynamic> days) async {
    if (days.length != 2) return false;

    print('Analizando si es FULL BODY...');

    final Map<String, Set<String>> muscleGroups = {
      'push': {'chest', 'shoulders', 'triceps'},
      'pull': {'back', 'biceps', 'traps', 'lats'},
      'legs': {'quadriceps', 'hamstrings', 'calves', 'glutes'},
    };

    Future<bool> containsAllMuscleGroups(List<dynamic> exercises) async {
      bool hasPush = false;
      bool hasPull = false;
      bool hasLegs = false;

      for (var exercise in exercises) {
        final muscles = await _getAllMusclesForExercise(exercise['exerciseID']);
        
        if (muscles.intersection(muscleGroups['push']!).isNotEmpty) {
          hasPush = true;
        }
        if (muscles.intersection(muscleGroups['pull']!).isNotEmpty) {
          hasPull = true;
        }
        if (muscles.intersection(muscleGroups['legs']!).isNotEmpty) {
          hasLegs = true;
        }
      }

      return hasPush && hasPull && hasLegs;
    }

    bool result = true;
    for (var day in days) {
      if (!await containsAllMuscleGroups(day['exercises'])) {
        result = false;
        break;
      }
    }

    print('¿Es FULL BODY?: $result');
    return result;
  }

  static Future<bool> _isUpperLowerSplit(List<dynamic> days) async {
    if (days.length != 4) return false;

    print('Analizando si es UPPER/LOWER...');

    Future<bool> isUpperDay(Map day) async {
      return await _containsMostlyMuscles(day['exercises'], {
        'chest', 'shoulders', 'triceps', 'back', 'biceps'
      });
    }

    Future<bool> isLowerDay(Map day) async {
      return await _containsMostlyMuscles(day['exercises'], {
        'quadriceps', 'hamstrings', 'calves', 'glutes'
      });
    }

    bool alternates = true;
    for (int i = 0; i < days.length; i++) {
      if (i % 2 == 0) {
        if (!await isUpperDay(days[i])) {
          alternates = false;
          break;
        }
      } else {
        if (!await isLowerDay(days[i])) {
          alternates = false;
          break;
        }
      }
    }

    print('¿Es UPPER/LOWER alternado?: $alternates');
    return alternates;
  }

  static Future<bool> _isBodyPartSplit(List<dynamic> days) async {
    print('Analizando si es BODY PART SPLIT...');
    if (days.length != 5) return false;

    Set<String> previousMuscles = {};
    for (var day in days) {
      Set<String> musclesToday = {};

      for (var exercise in day['exercises']) {
        final muscles = await _getAllMusclesForExercise(exercise['exerciseID']);
        musclesToday.addAll(muscles);
      }

      print('Músculos trabajados hoy (primarios y secundarios): $musclesToday');

      if (previousMuscles.isNotEmpty &&
          musclesToday.intersection(previousMuscles).length > 2) {
        print('Mucho solapamiento muscular, NO es body part split.');
        return false;
      }

      previousMuscles = musclesToday;
    }

    print('¿Es BODY PART SPLIT?: true');
    return true;
  }

  static Future<bool> _isCardioFocused(List<dynamic> days) async {
    print('Analizando si es CARDIO...');

    int cardioExercises = 0;
    int totalExercises = 0;

    const int repThreshold = 15;
    const int seriesThreshold = 4;
    const int minDaysThreshold = 4;

    int totalDays = days.length;
    bool isHighFrequency = totalDays >= minDaysThreshold;

    for (var day in days) {
      for (var exercise in day['exercises']) {
        totalExercises++;

        int reps = exercise['reps'] ?? 0;
        int sets = exercise['sets'] ?? 0;

        if (reps >= repThreshold && sets >= seriesThreshold) {
          cardioExercises++;
        }
      }
    }

    print('Ejercicios cardio: $cardioExercises de un total de $totalExercises');
    print('Número total de días: $totalDays');

    bool result = cardioExercises / totalExercises > 0.5 || isHighFrequency;
    
    print('¿Es CARDIO?: $result');
    return result;
  }

  static Future<String> _determineRoutineLevel(List<dynamic> days) async {
    print('--- Determinando nivel de rutina ---');
    String highestLevel = 'beginner';

    for (var day in days) {
      for (var exercise in day['exercises']) {
        final exerciseDetails = await _getExerciseDetails(exercise['exerciseID']);
        
        if (exerciseDetails != null && exerciseDetails['level'] != null) {
          String exerciseLevel = exerciseDetails['level']?.toLowerCase() ?? 'beginner';

          print('Nivel del ejercicio: $exerciseLevel');

          if (exerciseLevel == 'expert') {
            print('Nivel experto encontrado. Terminando búsqueda.');
            return 'expert';
          }

          if (exerciseLevel == 'intermediate' && highestLevel != 'expert') {
            highestLevel = 'intermediate';
          }
        }
      }
    }

    print('Nivel de rutina: $highestLevel');
    return highestLevel;
  }

  static Future<bool> addRating(routine, vote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Usuario no autenticado');
    }


    final routineRef = FirebaseFirestore.instance
    .collection("marketplace")
    .doc(routine["rID"]);

    routine["totalVotes"][user.uid] = vote;
    var values = routine["totalVotes"].values;
    var newAvg = values.reduce((a, b) => a + b)/values.length; 


    await routineRef.update({
      'totalVotes': routine["totalVotes"],
      'averageRating' : newAvg
    });

    return true;
    

  }

  static Future<bool> deleteRoutine(routine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Usuario no autenticado');
    }

    final routineRef = FirebaseFirestore.instance
    .collection("marketplace")
    .doc(routine["rID"]);

    await routineRef.delete();

    return true;
  }

  static bool isOwner (String creatorId){
    return FirebaseAuth.instance.currentUser?.uid == creatorId;
  }
}