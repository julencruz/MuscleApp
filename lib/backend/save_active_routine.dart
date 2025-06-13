import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscle_app/backend/achievement_manager.dart';

class SaveActiveRoutine {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> updateActiveRoutine(int newIndex, List<Map<String, dynamic>> routines) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) throw Exception('Usuario no autenticado');

  if (newIndex < 0 || newIndex >= routines.length) {
    throw Exception('Índice fuera de rango');
  }

  int? previousActiveIndex;

  for (int i = 0; i < routines.length; i++) {
    if (routines[i]['isActive'] == true) {
      previousActiveIndex = i;
      break;
    }
  }

  if (previousActiveIndex == newIndex) {
    // No hay cambio, no hacemos nada
    return;
  }

  // Cambiar la anterior rutina activa a false
  if (previousActiveIndex != null) {
    routines[previousActiveIndex]['isActive'] = false;
  }

  // Cambiar la nueva rutina activa a true (añadiendo el campo si no existe)
  routines[newIndex]['isActive'] = true;

  // Logro de probar una rutina de la marketplace
  if (routines[newIndex]['creatorId'] != uid && routines[newIndex]['creatorId'] != null && routines[newIndex]['creatorId'] != "MuscleApp") {
    AchievementManager().unlockAchievement("explorer");
  }

  // Guardar los cambios en Firestore
  final docRef = _firestore.collection('library').doc(uid);
  await docRef.update({'routines': routines});
}

}