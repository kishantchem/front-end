import 'package:cotton/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightThemeData(BuildContext context) {
  return ThemeData.light().copyWith(
    primaryColor: mainPrimaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: appBarTheme,
    iconTheme: const IconThemeData(color: mainContentColorLightTheme),
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: mainContentColorLightTheme),
    colorScheme: const ColorScheme.light(
      primary: mainPrimaryColor,
      secondary: mainSecondaryColor,
      error: mainErrorColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: mainContentColorLightTheme.withOpacity(0.7),
      unselectedItemColor: mainContentColorLightTheme.withOpacity(0.32),
      selectedIconTheme: const IconThemeData(color: mainPrimaryColor),
      showUnselectedLabels: true,
    ),
  );
}

ThemeData darkThemeData(BuildContext context) {
  return ThemeData.dark().copyWith(
    primaryColor: mainPrimaryColor,
    scaffoldBackgroundColor: mainContentColorLightTheme,
    appBarTheme: appBarTheme,
    iconTheme: const IconThemeData(color: mainContentColorDarkTheme),
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: mainContentColorDarkTheme),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: mainPrimaryColor,
      secondary: mainSecondaryColor,
      error: mainErrorColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: mainContentColorLightTheme,
      selectedItemColor: Colors.white70,
      unselectedItemColor: mainContentColorDarkTheme.withOpacity(0.32),
      selectedIconTheme: const IconThemeData(color: mainPrimaryColor),
      showUnselectedLabels: true,
    ),
  );
}

const appBarTheme =
    AppBarTheme(centerTitle: false, elevation: 0, color: mainPrimaryColor);
