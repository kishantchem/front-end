import 'package:cotton/providers/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/splash.dart'; // Import the Splash Screen

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cotton',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.white,
        appBarTheme: const AppBarTheme(
            color: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
                color: Colors.black, fontFamily: 'Inter', fontSize: 24)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: Colors.black, fontFamily: 'Inter'),
        ),
        colorScheme: const ColorScheme.light(background: Colors.white),
      ),
      home: const SplashScreen(), // Show the Splash Screen first
    );
  }
}