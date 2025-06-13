import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> getCreatorNameFromId(creatorId) async {
    final userDoc = await _firestore.collection('users').doc(creatorId).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData.containsKey('nombre')) {
        return userData['nombre'];
      } else {
        return 'Nombre no disponible';
      }
    } else {
      return 'Usuario no encontrado';
    }
  }
}