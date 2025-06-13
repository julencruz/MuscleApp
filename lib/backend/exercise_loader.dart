import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class ExerciseLoader {
  static List<Map<String, dynamic>>? _cachedExercises;
  static List<Map<String, dynamic>>? _cachedExercisesDetails;
  
  static Future<List<Map<String, dynamic>>> importExercises() async {
    // Retornar la caché si existe
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }

    // Si no hay caché, cargar desde el archivo
    String data = await rootBundle.loadString('assets/exercises.json');
    List<dynamic> exercises = jsonDecode(data);
    final parsedExercises = [
        for (var exercise in exercises) {
            'eID': exercise['id'],
            'name': exercise['name'],
            'bodyPart': exercise['primaryMuscles'][0],
            'primaryMuscles': exercise['primaryMuscles'],
            'secondaryMuscles': exercise['secondaryMuscles'],
            'instructions': exercise['instructions'],
            'images': exercise['images'],
            'level': exercise['level'],
            'icon': Colors.redAccent
        }
    ];

    // Guardar en caché antes de retornar
    _cachedExercises = parsedExercises;
    return parsedExercises;
  }

  static Future<List<Map<String, dynamic>>> importExercisesDetails() async {
    // Retornar la caché si existe
    if (_cachedExercisesDetails != null) {
      return _cachedExercisesDetails!;
    }

    // Si no hay caché, cargar desde el archivo
    String data = await rootBundle.loadString('assets/exercises.json');
    List<dynamic> exercises = jsonDecode(data);
    final parsedExercises = [
        for (var exercise in exercises) {
            'name': exercise['name'],
            'force': exercise['force'],
            'level': exercise['level'], 
            'mechanic': exercise['mechanic'],
            'equipment': exercise['equipment'],
            'primaryMuscles': exercise['primaryMuscles'],
            'secondaryMuscles': exercise['secondaryMuscles'],
            'instructions': exercise['instructions'],
            'category': exercise['category'],
            'images': exercise['images'],
            'id': exercise['id']
        }
    ];

    // Guardar en caché antes de retornar
    _cachedExercisesDetails = parsedExercises;
    return parsedExercises;
  }

  // Método para limpiar la caché si es necesario
  static void clearCache() {
    _cachedExercises = null;
    _cachedExercisesDetails = null;
  }

  static Future<Map<String, dynamic>?> getExerciseById(String id) async {
    final exercises = await importExercises();
    try {
      return exercises.firstWhere((exercise) => exercise['eID'] == id);
    } catch (e) {
      return null;
    }
  }
}