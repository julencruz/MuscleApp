import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:muscle_app/backend/new_user_init.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register a new user
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
        
      print("Succesfully signed in");
      await AchievementManager().initialize();
      return result;
    } catch (e) {
      print("Error registering: $e");
      return null; // Or handle the error more gracefully
    }
  }

  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print('Correo de recuperación enviado');
      return true;
    } catch (e) {
      print('Error al enviar el correo de recuperación: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("Succesfully authenticated");
      await AchievementManager().initialize();
      return result;
    } catch (e) {
      print("Error signing in: $e");
      return null; // Or handle the error more gracefully
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }


  Future<UserCredential?> signInWithGoogle() async {
    try {
      print("-1");
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      print("-2");
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      print("0");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("1");
      final result = await _auth.signInWithCredential(credential);
      print("2");
      
      if (result.additionalUserInfo?.isNewUser ?? false) {
        NewUserInit.newUserInit(result, "User");
        print('🆕 Usuario nuevo creado');
      } 

      return result;

    } catch (e) {
      print(e);
      return null;
    }
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
  Stream<User?> get authStateChanges => _auth.authStateChanges();

}