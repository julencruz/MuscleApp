import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoutineService {
  static Future<List<Map<String, dynamic>>> getUserRoutines() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      throw Exception('Usuario no autenticado');
    }

    final docRef = FirebaseFirestore.instance.collection('library').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      print('No existe el documento para este usuario.');
      return [];
    }

    final data = docSnap.data();
    if (data == null || !data.containsKey('routines')) {
      print('El documento no contiene rutinas.');
      return [];
    }

    final List<dynamic> routinesRaw = data['routines'];
    return routinesRaw.map((routine) => Map<String, dynamic>.from(routine)).toList();
  }
}
