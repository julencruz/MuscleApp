// profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio modular para manejar la actualización del perfil de usuario en Firebase
class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Actualiza los campos del perfil: nombre, género y unidad
  Future<void> updateUserProfile({
    required String name,
    required String gender,
    required String unit,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Usuario no autenticado',
      );
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set({
      'nombre': name,
      'genero': gender,
      'unidades': unit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}