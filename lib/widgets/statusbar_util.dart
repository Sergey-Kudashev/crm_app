import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class StatusBarUtil {
  static void setForDrawer({required bool isOpened}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isOpened ? const Color(0xFF673AB7) : Colors.transparent,
        statusBarIconBrightness:
            isOpened ? Brightness.light : Brightness.dark,
      ),
    );
  }

  static void forceColor(Color color, {Brightness iconBrightness = Brightness.light}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: iconBrightness,
      ),
    );
  }
}
