import "package:cloud_firestore/cloud_firestore.dart";
import 'package:firebase_auth/firebase_auth.dart';

class NewUserInit {
  
  static Future<void> addUserToStats(String userId) async{
      try {
      await FirebaseFirestore.instance
          .collection('stats')
          .doc(userId) 
          .set({
            'exercises': {},
            'muscles': {},
          });
    
    print('Usuario ${userId} añadido correctamente a la colección stats');
  } catch (e) {
    print('Error al añadir usuario: $e');
    throw e;
  }
}

  static Future<void> addUserToCalendar(String userId) async{
      try {
        await FirebaseFirestore.instance
            .collection('calendar')
            .doc(userId) 
            .set({
              'streak': 0,
              'daysRegistered': [] 
            });
      
      print('Usuario ${userId} añadido correctamente a la colección calendar');
    } catch (e) {
      print('Error al añadir usuario: $e');
      throw e;
    }
  }
  
  static Future<void> addUserToLibrary(String userId) async{
    try {
      await FirebaseFirestore.instance
          .collection('library')
          .doc(userId) 
          .set({
            'routines': [], 
          });
    
    print('Usuario ${userId} añadido correctamente a la colección library');
  } catch (e) {
    print('Error al añadir usuario: $e');
    throw e;
  }
  }

  static Future<void> addUserToUsers(String userId, String name) async{
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) 
          .set({
            'nombre': name,
            'genero': '',     
            'unidades': 'metric'   
          });
    
    print('Usuario ${userId} añadido correctamente a la colección users');
  } catch (e) {
    print('Error al añadir usuario: $e');
    throw e;
  }
}

  static Future<void> addUserToAchievements(String userId) async{
      try {
      await FirebaseFirestore.instance
          .collection('achievements')
          .doc(userId) 
          .set({
            'achiev': {
              'start_journey': false,
              'share_routine': false,
              'first_review': false,
              'first_training': false,
              'streak_7': false,
              'streak_30': false,
              'streak_90': false,
              'explorer': false,
              'mentor_badge': false,
              'legend_badge': false,
              'early_training': false,
              'night_owl': false,
              'focus_mode': false,
              'skip_rest_time': false,
              'view_warmup': false,
            }
          });
    
    print('Usuario ${userId} añadido correctamente a la colección stats');
  } catch (e) {
    print('Error al añadir usuario: $e');
    throw e;
  }
}

  static Future<void> newUserInit(UserCredential credential, String name) async {
    print("Entro en el newUserInit");
    final user = credential.user;
    addUserToStats(user!.uid);
    addUserToUsers(user.uid, name);
    addUserToLibrary(user.uid);
    addUserToCalendar(user.uid);
    addUserToAchievements(user.uid);
  }
}