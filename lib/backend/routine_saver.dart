import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscle_app/backend/achievement_manager.dart';


class RoutineSaver {
  static Future<void> addRoutineToUserLibrary(
    TextEditingController nameController,
    TextEditingController restTimeController,
    Map<int, dynamic> exercisesByDay,
    List<String> dayTypes,
  ) async {
    try {
      // 1. Verificación robusta de autenticación
      print(nameController.text);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        throw Exception('Usuario no autenticado');
      }

      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final routineId = const Uuid().v4();

      // Filtramos los días que tienen ejercicios
      final daysWithExercises = exercisesByDay.entries
          .where((entry) => entry.value != null && (entry.value as List).isNotEmpty)
          .toList();

      final routine = {
        'rID': routineId,
        'rName': nameController.text, 
        'restTime': int.tryParse(restTimeController.text) ?? 90,
        'isActive': false,
        'days': [
          for (var entry in daysWithExercises) 
            {
              'dayName': dayTypes[entry.key],
              'weekDay': weekdays[entry.key],
              'exercises': [
                for(var exercise in entry.value) { 
                  'exerciseID': exercise['eID'],
                  'exerciseName': exercise["name"],
                  'lastWeight': 0,
                  if (exercise['duration'] != null) ...{
                    'duration': exercise['duration'] ?? 0,
                    'reps': null,
                    'series': exercise['series'] ?? 0
                   } else ...{
                    'duration': null,
                    'reps': exercise['reps'] ?? 0,
                    'series': exercise['series'] ?? 0
                  }
                }
              ]
            }
        ],
      };

      final userLibraryRef = FirebaseFirestore.instance
          .collection('library')
          .doc(user.uid);
      
      // Usamos FieldValue.arrayUnion para añadir al array sin sobrescribir
      await userLibraryRef.update({
        'routines': FieldValue.arrayUnion([routine])
      });

      AchievementManager().unlockAchievement("start_journey");
      
      print('Rutina añadida correctamente');
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.message}');
      throw Exception('Error de autenticación: ${e.message}');
    } on FirebaseException catch (e) {
      print('Error de Firestore: ${e.message}');
      throw Exception('Error al guardar rutina: ${e.message}');
    } catch (e) {
      print('Error inesperado: $e');
      throw Exception('Error inesperado');
    }
  }

  static Future<List<Map<String, dynamic>>> updateRoutineInUserLibrary(
    TextEditingController nameController,
    TextEditingController restTimeController,
    Map<int, dynamic> exercisesByDay,
    List<String> dayTypes,
    String routineID,
    int index,
    List<Map<String, dynamic>> routines
  ) async {
    try {
      // 1. Verificación de autenticación
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        throw Exception('Usuario no autenticado');
      }

      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      // 2. Recuperar la rutina antigua y su estado activo
      final oldRoutine = routines[index];
      final wasActive = oldRoutine['isActive'] ?? false;

      // Filtramos los días que tienen ejercicios
      final daysWithExercises = exercisesByDay.entries
          .where((entry) => entry.value != null && (entry.value as List).isNotEmpty)
          .toList();

      // 3. Crear la nueva rutina, conservando los campos antiguos que no quieres perder
      final updatedRoutine = {
        ...oldRoutine,
        'rID': routineID,
        'rName': nameController.text,
        'restTime': int.tryParse(restTimeController.text) ?? 90,
        'isActive': wasActive,
        'days': [
          for (var entry in daysWithExercises)
            {
              'dayName': dayTypes[entry.key],
              'weekDay': weekdays[entry.key],
              'exercises': [
                for (var exercise in entry.value) {
                  'exerciseID': exercise['eID'],
                  'exerciseName': exercise['name'],
                  'lastWeight': 0,
                  if (exercise['duration'] != null) ...{
                    'duration': exercise['duration'] ?? 0,
                    'reps': null,
                    'series': exercise['series'] ?? 0
                   } else ...{
                    'duration': null,
                    'reps': exercise['reps'] ?? 0,
                    'series': exercise['series'] ?? 0
                   }
                }
              ]
            }
        ],
      };

      // 4. Actualizar lista de rutinas
      routines.removeAt(index);
      List<Map<String, dynamic>> updatedRoutines = List.from(routines);
      updatedRoutines.insert(0, updatedRoutine);

      // 5. Subir a Firestore
      final userLibraryRef = FirebaseFirestore.instance
          .collection('library')
          .doc(user.uid);

      await userLibraryRef.update({
        'routines': updatedRoutines
      });

      print('Rutina actualizada correctamente');
      return updatedRoutines;
      
    } on FirebaseAuthException catch (e) {
      print('Error de autenticación: ${e.message}');
      throw Exception('Error de autenticación: ${e.message}');
    } on FirebaseException catch (e) {
      print('Error de Firestore: ${e.message}');
      throw Exception('Error al guardar rutina: ${e.message}');
    } catch (e) {
      print('Error inesperado: $e');
      throw Exception('Error inesperado');
    }
  }

  static Future<List<Map<String, dynamic>>> removeRoutine(routines, index) async{
    try {
      final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.isAnonymous) {
          throw Exception('Usuario no autenticado');
        }

      routines.removeAt(index);
      final userLibraryRef = FirebaseFirestore.instance
      .collection("library")
      .doc(user.uid);
      
      await userLibraryRef.update({
        'routines': routines
      });
      print('Rutina eliminada correctamente');
      return routines;
    } catch (e){
      print('Error inesperado: $e');
      throw Exception('Error inesperado');
    }
    
  }

    static Future<void> saveRoutineFromMarketplace(routine) async{
    try {
      final user = FirebaseAuth.instance.currentUser;
        if (user == null || user.isAnonymous) {
          throw Exception('Usuario no autenticado');
        }
      routine.remove("totalVotes");
      routine.remove("averageRating");
      routine.remove("downloads");

      final userLibraryRef = FirebaseFirestore.instance
      .collection("library")
      .doc(user.uid);
      
      await userLibraryRef.update({
        'routines': FieldValue.arrayUnion([routine])
      });



      print('Rutina guardada correctamente');
    } catch (e){
      print('Error inesperado: $e');
      throw Exception('Error inesperado');
    }
    
  }
}