import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData appTheme = ThemeData(
  useMaterial3: false,
  brightness: Brightness.light,
  primaryColor: Colors.black,
  colorScheme: ColorScheme.fromSwatch().copyWith(primary: Colors.black, secondary: Colors.black),
  fontFamily: 'Nunito',
  popupMenuTheme: const PopupMenuThemeData(color: Colors.black),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    titleTextStyle: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold, color: Colors.black),
  ),
  scaffoldBackgroundColor: lightBlueColor,
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Colors.black, width: 2),
    ),
  ),
);

// Design system colors
const Color skyBlueColor = Color(0xff00D7FF);
const Color lightSkyBlue = Color(0xffB3E9F0);
const Color lightBlueColor = Color(0xffF8FAFC);
const Color disabledGrey = Color(0xff989898);
const Color grey = Color(0xffC4C4C4);

void systemUIOverlayStyle() => SystemChrome.setSystemUIOverlayStyle(
  SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Make status bar transparent
    systemNavigationBarColor: Colors.black,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  ),
);
