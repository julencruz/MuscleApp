import 'package:flutter/material.dart';

late Color primaryColor;
late Color backgroundColor;
late Color textColor;
late Color redColor;
late Color cardColor;
late Color dividerColor;
late Color hintColor;
late Color failedColor;
late Color disabledColor; // Para elementos deshabilitados
late Color accentColor;
late Color textColor2; // Para texto secundario
late Color shadowColor;
late Color contraryTextColor; // Para texto en fondos oscuros
late Color appBarBackgroundColor;
late Color snackBarBackgroundColor;

void setLightThemeColors() {
  redColor = Color(0xFFA90015);
  backgroundColor = Colors.grey[50]!;
  appBarBackgroundColor = Colors.white; 
  cardColor = Colors.white; // Para tarjetas y superficies
  shadowColor = Colors.grey.withOpacity(0.08);
  hintColor = Colors.grey[600]!; // Para texto secundario
  contraryTextColor = Colors.white; // Para texto en fondos oscuros
  textColor = Colors.black;
  textColor2 = Colors.black87; // Para texto secundario
  failedColor = Colors.grey[200]!; // Para elementos deshabilitados
  dividerColor = Colors.grey[300]!;
  disabledColor = Colors.grey[200]!;
  snackBarBackgroundColor = Color(0xFF232323);
}

void setDarkThemeColors() {
  redColor = Color(0xFFA90015);
  backgroundColor = Color(0xFF121212);
  appBarBackgroundColor = Color(0xFF1E1E1E); // Para la barra de navegación
  contraryTextColor = Colors.black; // Para texto en fondos oscuros
  textColor = Colors.white;
  textColor2 = const Color.fromARGB(255, 226, 226, 226); // Para texto secundario
  shadowColor = Colors.white.withOpacity(0.016);
  cardColor = Color(0xFF1E1E1E);    // Para tarjetas y superficies
  dividerColor = Color(0xFF333333); // Para separadores
  hintColor = const Color.fromARGB(255, 192, 192, 192);    // Para texto secundario
  failedColor = Colors.grey[800]!; // Para elementos deshabilitados
  accentColor = Color(0xFFBB86FC);  // Un morado/lila para acentos secundarios
  disabledColor = Colors.grey[800]!;
  snackBarBackgroundColor = Colors.white;
}