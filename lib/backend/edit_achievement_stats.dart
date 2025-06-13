import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class editAchievement {
  static Future<Map<String, dynamic>> getAchievementStats() async {
    print("Hola");
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      throw Exception('Usuario no autenticado');
    }

    final docRef = FirebaseFirestore.instance.collection('achievements').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      print('No existe el documento para este usuario.');
      return {};
    }

    final data = docSnap.data();
    if (data == null || !data.containsKey('achiev')) {
      print('El documento no contiene logros.');
      return {};
    }

    final Map<String, dynamic> achievRaw = data['achiev'];
    return achievRaw;
  }

  static Future<void> setAchievementStats(Map<String, dynamic> newAchiev) async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.isAnonymous) {
      throw Exception('Usuario no autenticado');
    }

    final docRef = FirebaseFirestore.instance.collection('achievements').doc(user.uid);

    await docRef.set({
      'achiev': newAchiev
    });
  }

  static Future<void> setAchievementStatsToUser(String achievementId, String? uid) async {
    print(uid);
    final docRef = FirebaseFirestore.instance.collection('achievements').doc(uid);

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          final achievMap = data['achiev'] as Map<String, dynamic>? ?? {};
          achievMap[achievementId] = true;
          await docRef.update({'achiev': achievMap});
        } else {
          print('Advertencia: El documento existe pero no tiene datos o el campo "achiev".');
        }
      }
    } catch (e) {
      print('Error al actualizar el logro: $e');
      rethrow;
    }
  }

}
