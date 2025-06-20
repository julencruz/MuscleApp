import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:muscle_app/backend/get_active_routine.dart';
import 'package:muscle_app/backend/notifs_service.dart';
import 'package:muscle_app/backend/routine_notifs.dart';
import 'package:muscle_app/backend/update_dock.dart';
import 'package:muscle_app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Obtener el tema guardado
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme') ?? 'system';

  bool useDark;

  if (savedTheme == 'light') {
    useDark = false;
  } else if (savedTheme == 'dark') {
    useDark = true;
  } else {
    // Detectar tema del sistema si es 'system'
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    useDark = brightness == Brightness.dark;
  }

  if (useDark) {
    setDarkThemeColors();
  } else {
    setLightThemeColors();
  }

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
        colorScheme: backgroundColor == Colors.white
            ? ColorScheme.fromSeed(
                seedColor: Colors.white,
                primary: Colors.white,
                brightness: Brightness.light,
                surface: backgroundColor,
                background: backgroundColor,
              )
            : ColorScheme.fromSeed(
                seedColor: Colors.black,
                primary: Colors.black,
                brightness: Brightness.dark,
                surface: backgroundColor,
                background: backgroundColor,
              ),
        useMaterial3: true,
        // Configurar colores específicos para evitar flashes
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: appBarBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: textColor,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: textColor, size: 32),
        ),
        cardColor: cardColor,
        // Configurar colores adicionales para evitar inconsistencias
        canvasColor: backgroundColor,
        dialogBackgroundColor: cardColor,
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: cardColor,
          modalBackgroundColor: cardColor,
        ),
        // Configurar el color de fondo de los diálogos y overlays
        cardTheme: CardTheme(
          color: cardColor,
          surfaceTintColor: Colors.transparent,
        ),
        // Configurar el tema del loading indicator
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: redColor,
        ),
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
            return Scaffold(
              backgroundColor: backgroundColor, // Asegurar color de fondo consistente
              body: Center(
                child: CircularProgressIndicator(
                  color: redColor, // Color consistente con tu tema
                ),
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