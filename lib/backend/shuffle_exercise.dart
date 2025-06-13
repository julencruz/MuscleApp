import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';

class ShuffleExercise {
  static Future<Map<String, dynamic>> getEquivalentExercise(Map<String, dynamic> exercise) async {
  try {
    // 1. Cargar el JSON de ejercicios
    final String response = await rootBundle.loadString('assets/exercises.json');
    final List<dynamic> allExercises = jsonDecode(response);
    
    // 2. Obtener los músculos primarios del ejercicio actual
    final currentExercise = allExercises.firstWhere(
      (ex) => ex['id'] == exercise['exerciseID'],
      orElse: () => null,
    );
    
    if (currentExercise == null) {
      throw Exception('Ejercicio actual no encontrado en la base de datos');
    }
    
    final List<String> primaryMuscles = List<String>.from(currentExercise['primaryMuscles'] ?? []);
    
    if (primaryMuscles.isEmpty) {
      throw Exception('El ejercicio no tiene músculos primarios definidos');
    }
    
    // 3. Filtrar ejercicios que compartan al menos un músculo primario
    final equivalentExercises = allExercises.where((ex) {
      // Excluir el ejercicio actual
      if (ex['id'] == exercise['exerciseID']) return false;
      
      final List<String> otherPrimaryMuscles = List<String>.from(ex['primaryMuscles'] ?? []);
      return otherPrimaryMuscles.any((muscle) => primaryMuscles.contains(muscle));
    }).toList();
    
    if (equivalentExercises.isEmpty) {
      throw Exception('No se encontraron ejercicios equivalentes');
    }
    
    // 4. Seleccionar un ejercicio aleatorio
    final randomIndex = Random().nextInt(equivalentExercises.length);
    final selectedExercise = equivalentExercises[randomIndex];
    
    // 5. Preparar el resultado manteniendo la estructura del ejercicio original
    return {
      ...exercise, // Mantener todas las propiedades originales
      'exerciseID': selectedExercise['id'],
      'exerciseName': selectedExercise['name'],
      // Mantener las series, reps y peso del ejercicio original
      'series': exercise['series'],
      'reps': exercise['reps'],
      'lastWeight': exercise['lastWeight'],
    };
    
  } catch (e) {
    print('🔥 Error al buscar ejercicio equivalente: $e');
    // Devuelve el ejercicio original si hay error
    return exercise;
  }
}
}