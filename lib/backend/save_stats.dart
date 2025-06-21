import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'dart:math';
import 'package:muscle_app/backend/get_active_routine.dart';

class StatsSaver {
  static Future<void> saveStats(
  List<List<String>> currentWeights,
  List<List<String>> currentReps,
  List<dynamic> exercises,
  List<List<bool>> seriesDone,
  bool focus
) async {
  try {
    print("🟢 Iniciando guardado de estadísticas");
    print("📋 Ejercicios recibidos: $exercises");

    if (exercises.isEmpty || currentWeights.isEmpty) {
      throw Exception('❌ Listas de ejercicios o pesos vacías');
    }

    if (exercises.length != currentWeights.length) {
      throw Exception('❌ La cantidad de ejercicios no coincide con los pesos proporcionados');
    }

    final weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final today = weekDays[DateTime.now().weekday - 1];
    print("📆 Hoy es: $today");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception(user == null ? '❌ No hay usuario logueado' : '❌ Usuario anónimo no permitido');
    }

    // Crear currentVolume multiplicando pesos por reps
    List<List<String>> currentVolume = [];
    for (int i = 0; i < currentWeights.length; i++) {
      List<String> volumePerExercise = [];
      for (int j = 0; j < currentWeights[i].length; j++) {
        final weight = int.tryParse(currentWeights[i][j].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final reps = int.tryParse(currentReps[i][j].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        volumePerExercise.add((weight * reps).toString());
      }
      currentVolume.add(volumePerExercise);
    }

    print('📦 currentVolume calculado: $currentVolume');

    // Filtrar las series completadas
    List<List<String>> completedWeights = [];
    List<List<String>> completedVolumes = [];

    for (int i = 0; i < currentWeights.length; i++) {
      completedWeights.add([]);
      completedVolumes.add([]);
    }

    for (int i = 0; i < currentWeights.length; i++) {
      for (int j = 0; j < currentWeights[i].length; j++) {
        if (seriesDone[i][j]) {
          completedWeights[i].add(currentWeights[i][j]);
          completedVolumes[i].add(currentVolume[i][j]);
        }
      }
    }

    final Map<String, int> exerciseWeights = {};
    final Map<String, int> exerciseVolumes = {};

    for (int i = 0; i < exercises.length; i++) {
      if (completedWeights[i].isNotEmpty) {
        final exercise = exercises[i];
        if (exercise is! Map<String, dynamic>) {
          print('⚠️ Ejercicio en posición $i no es válido');
          continue;
        }

        final exerciseId = exercise['exerciseID']?.toString();
        if (exerciseId == null || exerciseId.isEmpty) {
          print('⚠️ Ejercicio en posición $i no tiene ID válido');
          continue;
        }

        final weights = completedWeights[i]
            .map((w) => int.tryParse(w.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
            .where((w) => w > 0)
            .toList();

        final volumes = completedVolumes[i]
            .map((v) => int.tryParse(v) ?? 0)
            .where((v) => v > 0)
            .toList();

        if (weights.isNotEmpty) {
          final maxWeight = weights.reduce(max);
          exerciseWeights[exerciseId] = maxWeight;
          print('✅ Procesado ejercicio $exerciseId con peso máximo $maxWeight');
        }

        if (volumes.isNotEmpty) {
          final totalVolume = volumes.reduce((a, b) => a + b);
          exerciseVolumes[exerciseId] = totalVolume;
        }
      }
    }

    print('📊 Volúmenes calculados: $exerciseVolumes');
    final muscleVolumes = await calculateMuscleVolume(exerciseVolumes);
    print('📊 Volúmenes por músculo: $muscleVolumes');


    print('🟠 Actualizando rutina...');
    await updateExercisesLastWeights(exerciseWeights, user.uid, today);

    print('🟢 Actualizando estadísticas...');
    await updateExercisesStats(exerciseWeights, user.uid);
    print('🟢 Actualizando volumenes...');
    await updateMuscleVolumes(muscleVolumes, user.uid);
    print('🎉 Estadísticas guardadas exitosamente');

    AchievementManager().unlockAchievement("first_training");
    if(focus){
      AchievementManager().unlockAchievement("focus_mode");
    }
    if(DateTime.now().hour <= 7){
      AchievementManager().unlockAchievement("early_training");
    }
    if(DateTime.now().hour >= 23){
      AchievementManager().unlockAchievement("night_owl");
    }

    await registerDayCompleted(user.uid);
    print('✅ Día registrado exitosamente');

  } on FirebaseException catch (e) {
    print('🔥 Error de Firebase: ${e.code} - ${e.message}');
    throw Exception('Error al conectar con la base de datos: ${e.message}');
  } catch (e, stackTrace) {
    print('🔥 Error en saveStats: $e\nStack trace: $stackTrace');
    throw Exception('Error al guardar estadísticas: ${e.toString()}');
  }
}


  static Future<void> updateExercisesLastWeights(Map<String, int> exerciseWeights, String uid, String today) async {
    print("🟠 Actualizando últimos pesos para UID: $uid");
    final userLibraryRef = FirebaseFirestore.instance.collection('library').doc(uid);

    final userRoutinesDoc = await userLibraryRef.get(const GetOptions(source: Source.server));

    if (!userRoutinesDoc.exists) {
      throw Exception('❌ No se encontraron rutinas para el usuario');
    }

    List<dynamic> userRoutines = userRoutinesDoc.get('routines');
    List<dynamic> updatedRoutines = List.from(userRoutines);
    Map<String, dynamic>? activeRoutine = await ActiveRoutine.getActiveRoutine();
    if (activeRoutine == null) {
      throw Exception('❌ No se pudo obtener la rutina activa');
    }
    List<dynamic> days = List.from(activeRoutine["days"]);

    bool changesMade = false;

    for (int i = 0; i < days.length; i++) {
      Map<String, dynamic> day = Map.from(days[i]);

      if (day['weekDay'] == today) {
        List<dynamic> exercises = List.from(day['exercises']);

        for (int j = 0; j < exercises.length; j++) {
          Map<String, dynamic> exercise = Map.from(exercises[j]);
          if (exerciseWeights.containsKey(exercise['exerciseID'])) {
            int newWeight = exerciseWeights[exercise['exerciseID']]!;
            if (exercise['lastWeight'] != newWeight) {
              print('🔁 Actualizando ${exercise['exerciseID']} de ${exercise['lastWeight']} a $newWeight');
              exercise['lastWeight'] = newWeight;
              exercises[j] = exercise;
              changesMade = true;
            }
          }
        }

        if (changesMade) {
          day['exercises'] = exercises;
          days[i] = day;
          activeRoutine['days'] = days;
          updatedRoutines[0] = activeRoutine;

          await userLibraryRef.update({'routines': updatedRoutines});
          print('✅ Últimos pesos actualizados en Firestore.');
        } else {
          print('ℹ️ No hubo cambios en los pesos de los ejercicios.');
        }

        return;
      }
    }

    if (!changesMade) {
      throw Exception('❌ No se encontraron ejercicios para actualizar o el día no existe');
    }
  }

  static Future<void> updateExercisesStats(Map<String, int> exerciseWeights, String uid) async {
  try {
    final statsRef = FirebaseFirestore.instance.collection('stats').doc(uid);
    final now = DateTime.now();
    print("1");  // Se ejecuta antes de acceder a Firestore

    final docSnapshot = await statsRef.get();
    final data = docSnapshot.data() ?? {};
    print("2");  // Se ejecuta después de obtener los datos de Firestore

    final updates = <String, dynamic>{};
    
    // Inicializamos el mapa de 'exercises' si no existe
    final exercises = data['exercises'] ?? {};

    for (final entry in exerciseWeights.entries) {
      final exerciseId = entry.key;
      final newWeight = entry.value;
      print("3");  // Se ejecuta en cada iteración del ciclo de ejercicios
      // Asegurarnos de que cada ejercicio tenga una entrada en el mapa 'exercises'
      if (exercises[exerciseId] == null) {
        exercises[exerciseId] = {};  // Inicializamos el ejercicio si no existe
      }

      // Obtener los datos actuales del ejercicio o inicializarlo
      final exerciseData = exercises[exerciseId] ?? {};
      print("4");  // Después de obtener los datos de un ejercicio específico

      final currentPR = (exerciseData['pr'] is int) ? exerciseData['pr'] : 0;

      // Actualizar PR si es necesario
      final updatedPR = newWeight > currentPR ? newWeight : currentPR;
      exercises[exerciseId]['pr'] = updatedPR;  // Actualizamos PR para el ejercicio
      print("5");  // Después de actualizar PR si es necesario

      // Gestionar registros como una cola de máximo 7 elementos
      final List<dynamic> registry = exerciseData['registry'] != null
          ? List<dynamic>.from(exerciseData['registry'])
          : [];
      print("6");  // Después de preparar el registro

      registry.add({'date': now, 'weight': newWeight});

      if (registry.length > 7) {
        registry.removeRange(0, registry.length - 7);  // Mantener solo los últimos 7
      }

      exercises[exerciseId]['registry'] = registry;  // Actualizamos el registro para el ejercicio
      print("7");  // Después de actualizar el registro
    }

    // Guardamos las actualizaciones en Firestore
    updates['exercises'] = exercises;  // Actualizamos el campo 'exercises' completo
    await statsRef.set(updates, SetOptions(merge: true));
    print('Estadísticas actualizadas para $uid');  // Después de guardar la actualización

  } catch (e) {
    print('Error actualizando stats: $e');
    throw Exception('No se pudieron guardar las estadísticas');
  }
}


static Future<Map<String, double>> calculateMuscleVolume(Map<String, int> exerciseVolumes) async {
  try {
    // Cargar JSON desde assets
    final String response = await rootBundle.loadString('assets/exercises.json');
    final List<dynamic> exercisesData = jsonDecode(response);

    final Map<String, double> muscleVolumes = {};

    exerciseVolumes.forEach((exerciseId, volume) {
      final exercise = exercisesData.firstWhere(
        (ex) => ex['id'] == exerciseId,
        orElse: () => null,
      );

      if (exercise == null) {
        print("⚠️ Ejercicio con ID '$exerciseId' no encontrado en exercises.json");
        return;
      }

      // Sumar volumen a los músculos primarios
      List<dynamic> primaryMuscles = exercise['primaryMuscles'] ?? [];
      for (var muscle in primaryMuscles) {
        muscleVolumes[muscle] = (muscleVolumes[muscle] ?? 0) + volume;
      }

      // Sumar volumen/2 a los músculos secundarios
      List<dynamic> secondaryMuscles = exercise['secondaryMuscles'] ?? [];
      for (var muscle in secondaryMuscles) {
        muscleVolumes[muscle] = (muscleVolumes[muscle] ?? 0) + (volume / 2);
      }
    });

    return muscleVolumes;

  } catch (e) {
    print('🔥 Error al calcular volumen muscular: $e');
    throw Exception('Error calculando volumen muscular');
  }
}

static Future<void> updateMuscleVolumes(
  Map<String, double> muscleVolumes,
  String userId
) async {
  try {
    print("🧬 Iniciando actualización de volúmenes musculares en Firestore para el usuario: $userId");

    final userDocRef = FirebaseFirestore.instance.collection('stats').doc(userId);
    final snapshot = await userDocRef.get();

    if (!snapshot.exists) {
      throw Exception('❌ El documento de estadísticas para el usuario $userId no existe.');
    }

    final existingData = snapshot.data();

    Map<String, dynamic> updatedMuscleMap = existingData?['muscles'] != null
        ? Map<String, dynamic>.from(existingData!['muscles'])
        : {};

    final Timestamp? lastResetTimestamp = existingData?['lastReset'] as Timestamp?;
    final DateTime now = DateTime.now();
    final DateTime lastReset = lastResetTimestamp?.toDate() ?? DateTime(1970);
    
    // Si ha pasado más de 7 días desde el último reset
    if (now.difference(lastReset).inDays >= 7) {
      print('🔄 Han pasado más de 7 días. Reiniciando volúmenes musculares...');
      updatedMuscleMap = {};  // Reinicia el mapa de músculos

      await userDocRef.update({
        'muscles': updatedMuscleMap,
        'lastReset': Timestamp.fromDate(now),  // Actualiza la fecha del último reset
      });

      print('✅ Volúmenes reiniciados correctamente.');
    }

    // Suma los volúmenes
    muscleVolumes.forEach((muscle, volume) {
      final existingVolume = (updatedMuscleMap[muscle]?['totalVolume'] ?? 0).toDouble();
      final newVolume = existingVolume + volume;

      updatedMuscleMap[muscle] = {
        'totalVolume': newVolume,
      };

      print('💪 Actualizado $muscle: $existingVolume ➡️ $newVolume');
    });

    await userDocRef.update({
      'muscles': updatedMuscleMap,
    });

    print('✅ Volúmenes musculares actualizados correctamente en Firestore.');

  } on FirebaseException catch (e) {
    print('🔥 Error de Firebase: ${e.code} - ${e.message}');
    throw Exception('Error al actualizar volúmenes musculares: ${e.message}');
  } catch (e, stackTrace) {
    print('🔥 Error al actualizar músculos: $e\nStack trace: $stackTrace');
    throw Exception('Error inesperado al actualizar músculos: ${e.toString()}');
  }
}

  static Future<Map<String, Map<String, dynamic>>> fetchExerciseStats(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('stats').doc(uid).get();
    final data = doc.data() ?? {};
    final exercisesMap = Map<String, dynamic>.from(data['exercises'] ?? {});
    final Map<String, Map<String, dynamic>> result = {};

    exercisesMap.forEach((id, entry) {
      final ex = Map<String, dynamic>.from(entry);
      final pr = (ex['pr'] ?? 0).toDouble();

      final registryRaw = ex['registry'] as List<dynamic>? ?? [];
      final weightsWithDates = registryRaw.map<Map<String, dynamic>>((e) {
        final m = e as Map<String, dynamic>;
        final w = m['weight'];
        final d = m['date'];

        return {
          'weight': (w is num) ? w.toDouble() : double.tryParse('$w') ?? 0.0,
          'date'  : d, // puedes convertirlo a DateTime si es un timestamp
        };
      }).toList();

      result[id] = {
        'name'   : ex['name'] ?? 'Exercise $id',
        'weights': weightsWithDates,
        'pr'     : pr,
      };
    });

    return result;
  }

  /// Devuelve [volPush, volPull, volCore, volLegs]
  static Future<List<double>> fetchProportionData(String uid) async {
  final doc = await FirebaseFirestore.instance.collection('stats').doc(uid).get();
  final data = doc.data() ?? {};
  //print('🔍 [fetchProportionData] raw data: $data');    // ← línea de debug
  final musclesMap = Map<String, dynamic>.from(data['muscles'] ?? {});

  final pushMuscles = ['triceps','chest','shoulders'];
  final pullMuscles = ['biceps','forearms','traps','lats','middle back','neck'];
  final coreMuscles = ['abdominals','lower back'];
  final legsMuscles = ['quadriceps','abductors','adductors','calves','glutes','hamstrings'];

  double sumGroup(List<String> group) =>
    group.fold(0.0, (sum, name) {
      final entry = musclesMap[name] as Map<String, dynamic>?;
      if (entry != null && entry['totalVolume'] != null) {
        return sum + (entry['totalVolume'] as num).toDouble();
      }
      return sum;
    });

    return [
      sumGroup(pushMuscles),
      sumGroup(pullMuscles),
      sumGroup(coreMuscles),
      sumGroup(legsMuscles),
    ];
  }

 ///Funcion para registrar días completados y racha
  static Future<void> registerDayCompleted(String uid) async {
    final userDocRef = FirebaseFirestore.instance.collection('calendar').doc(uid);
    final userDoc = await userDocRef.get();

    final routine = await ActiveRoutine.getActiveRoutine();
    print('Rutina activa: $routine');
    if (routine == null) throw Exception('❌ No se pudo obtener la rutina activa');

    // Mapear nombres de días a números
    Map<String, int> weekDayMap = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };

    // Obtener días activos de la rutina
    List<int> routineDays = [];
    for (var day in routine['days']) {
      final weekDayName = day['weekDay']; // ej: 'Friday'
      if (weekDayMap.containsKey(weekDayName)) {
        routineDays.add(weekDayMap[weekDayName]!);
      }
    }

    List<dynamic> rawDaysRegistered = userDoc['daysRegistered'];
    List<DateTime> daysRegistered = rawDaysRegistered.map((d) => (d as Timestamp).toDate()).toList();

    DateTime now = DateTime.now();
    int todayWeekday = now.weekday;

    if (!routineDays.contains(todayWeekday)) {
      throw Exception('❌ Hoy no toca entrenar según tu rutina');
    }

    if (daysRegistered.isNotEmpty && daysRegistered[0].month != now.month) {
      daysRegistered.clear();
    }

    if (daysRegistered.isNotEmpty && _isSameDay(daysRegistered[0], now)) {
      return;
    }

    daysRegistered.insert(0, now);

    int streak = 1;
    bool validStreak = true;

    if (daysRegistered.length > 1) {
      DateTime last = daysRegistered[1];

      List<DateTime> expectedDays = [];
      DateTime temp = last.add(Duration(days: 1));
      while (temp.isBefore(now)) {
        if (routineDays.contains(temp.weekday)) {
          expectedDays.add(temp);
        }
        temp = temp.add(Duration(days: 1));
      }

      for (DateTime expected in expectedDays) {
        bool wasDone = daysRegistered.any((d) => _isSameDay(d, expected));
        if (!wasDone) {
          validStreak = false;
          break;
        }
      }

      if (validStreak) {
        streak = (userDoc['streak'] ?? 0) + 1;
        if(streak == 7){
         AchievementManager().unlockAchievement("streak_7"); 
        }
        if(streak == 30){
         AchievementManager().unlockAchievement("streak_30"); 
        }
        if(streak == 90){
         AchievementManager().unlockAchievement("streak_90"); 
        }
      }
    }

    await userDocRef.update({
      'daysRegistered': daysRegistered,
      'streak': validStreak ? streak : 1,
    });
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<int> getStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('❌ No se encontró un usuario logueado');
    }
    final userDocRef = FirebaseFirestore.instance.collection('calendar').doc(user.uid);
    final userDoc = await userDocRef.get();

    final List<dynamic> rawDaysRegistered = userDoc['daysRegistered'] ?? [];
    final List<DateTime> daysRegistered = rawDaysRegistered
        .map((d) => (d as Timestamp).toDate())
        .toList()
        ..sort((a, b) => b.compareTo(a)); // Orden descendente

    DateTime today = DateTime.now();
    int streak = 0;

    // Calcular streak real (días consecutivos hasta hoy)
    for (int i = 0; i < daysRegistered.length; i++) {
      final expectedDay = today.subtract(Duration(days: i));
      final registeredDay = daysRegistered[i];
      if (_isSameDay(registeredDay, expectedDay)) {
        streak++;
      } else {
        break;
      }
    }

    // Si el streak guardado es diferente al real, actualizarlo en Firestore
    if ((userDoc['streak'] ?? 0) != streak) {
      await userDocRef.update({'streak': streak});
    }

    return streak;
  }

}


