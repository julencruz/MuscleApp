import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:muscle_app/backend/get_active_routine.dart';
import 'package:muscle_app/backend/notifs_service.dart';
import 'package:muscle_app/backend/routine_notifs.dart';
import 'package:muscle_app/backend/update_dock.dart';
import 'backend/firebase_options.dart';
import 'package:muscle_app/frontend/login.dart';
import 'package:muscle_app/frontend/home.dart';
import 'package:muscle_app/backend/achievement_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar estilo de la barra de navegación
  UpdateDock.updateSystemUI(const Color.fromARGB(0, 250, 250, 250));

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotifsService.init();

  // Inicializar formato de fecha para español
  await initializeDateFormatting('es', null);
  
  // On app start, reschedule notifications for the active routine
  await _rescheduleActiveRoutineNotifications();
  
  await AchievementManager().initialize();

  runApp(const MyApp());
}

// Add this function to reschedule notifications for the active routine
Future<void> _rescheduleActiveRoutineNotifications() async {
  try {
    // Get the active routine
    final activeRoutine = await ActiveRoutine.getActiveRoutine();
    if (activeRoutine != null) {
      await RoutineNotificationManager.scheduleRoutineNotifications(activeRoutine);
    }
  } catch (e) {
    print('Error rescheduling notifications: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muscle App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey[50]!),
        useMaterial3: true,
      ),
      // Añadir soporte para localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'), // Español
        Locale('en'), // Inglés
      ],
      locale: const Locale('es'), // Forzar español como idioma predeterminado
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold( 
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}