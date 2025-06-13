
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveRoutine{
  
  static Future<Map<String, dynamic>?> getActiveRoutine() async{
      

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw Exception('Usuario no autenticado');
    }
    
    final userRoutineRef = FirebaseFirestore.instance
          .collection('library')
          .doc(user.uid);
    
    
    final userRoutinesDoc = await userRoutineRef.get();

    if (userRoutinesDoc.exists) {
      List<dynamic> userRoutines = userRoutinesDoc.get('routines');
      List<String> weekDays = [];
      for(var routine in userRoutines){
        if(routine["isActive"] == true){
          for(var day in routine["days"])
          {
            weekDays.add(day["weekDay"]);
          }
          routine["weekDays"] = weekDays;
          routine["amount"] = routine["days"].length;
          return routine;
        }
      }
    }

    print('No existe el documento');
    return null;
  }
}