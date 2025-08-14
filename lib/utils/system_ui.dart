import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void setSystemUIOverlayStyle(bool isDarkMode) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );
}
