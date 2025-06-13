import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<DateTime>> getDaysRegistered() async {
    // Verificar autenticación
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Usuario no autenticado');
      throw Exception('Usuario no autenticado');
    }

    try {
      print('🔄 Obteniendo días registrados para el usuario: ${user.uid}');
      final snapshot = await _firestore
          .collection('calendar')
          .doc(user.uid)
          .get();

      if (!snapshot.exists) {
        print('ℹ️ No hay registros para este usuario');
        return [];
      }

      // Obtener la lista de Timestamps y convertirlos a DateTime
      final List<dynamic> rawDays = snapshot.data()?['daysRegistered'] ?? [];
      final List<DateTime> daysRegistered = rawDays
          .map((timestamp) => (timestamp as Timestamp).toDate())
          .toList();

      print('✅ Días registrados obtenidos: ${daysRegistered.length}');
      return daysRegistered;

    } on FirebaseException catch (e) {
      print('🔥 Error de Firebase: ${e.code} - ${e.message}');
      throw Exception('Error al obtener los días registrados: ${e.message}');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error inesperado al obtener los días registrados');
    }
  }

  static Future<List<int>> getActiveDays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Usuario no autenticado',
      );
    }

    try {
      print('🔄 Obteniendo días activos...');
      final doc = await _firestore.collection('library').doc(user.uid).get();
      if (!doc.exists) {
        print('ℹ️ No existe documento para el usuario');
        return [];
      }

      final data = doc.data()!;
      final routines = List<Map<String, dynamic>>.from(data['routines'] ?? []);
      
      // Buscar rutina activa
      final activeRoutine = routines.firstWhere(
        (r) => r['isActive'] == true,
        orElse: () => {'days': []},
      );

      if (activeRoutine.isEmpty) {
        print('ℹ️ No hay rutina activa');
        return [];
      }

      final days = List<Map<String, dynamic>>.from(activeRoutine['days'] ?? []);
      List<int> activeDays = [];
      
      // Convertir días a formato numérico (1-7)
      for (var day in days) {
        String weekDay = day['weekDay'];
        int dayIndex = _getWeekDayIndex(weekDay);
        if (dayIndex >= 0) {
          activeDays.add(dayIndex + 1); // Convertir a formato 1-7
        }
      }

      print('✅ Días activos encontrados: $activeDays');
      return activeDays..sort(); // Devolver ordenado

    } catch (e) {
      print('❌ Error obteniendo días activos: $e');
      return [];
    }
  }

  static int _getWeekDayIndex(String weekDay) {
    final Map<String, int> dayToIndex = {
      'Monday': 0,
      'Tuesday': 1,
      'Wednesday': 2,
      'Thursday': 3,
      'Friday': 4,
      'Saturday': 5,
      'Sunday': 6,
    };
    return dayToIndex[weekDay] ?? -1;
  }
}