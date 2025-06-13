import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateDock {
  static void updateSystemUI(Color color){
    final brightness = ThemeData.estimateBrightnessForColor(color);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: color,
      systemNavigationBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: color,
    ));
  }
}
