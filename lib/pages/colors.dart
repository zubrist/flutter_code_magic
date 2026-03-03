import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFB92B54);
  static const Color secondary = Color(0xFFF5EEE1);
  static const Color accent = Color(0xFF6A1B31);
  static const Color background = Color(0xFFF5EEE1);
  static const Color text = Color.fromRGBO(116, 0, 0, 1);
  static const Color textwhite = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  static const Color starColor = Color(0xFFFFD700);
  static const Color lightText = Color(0xFF777777);
  static const Color iconBackground = Color(0xFFFEF0E3);
  static const Gradient button = LinearGradient(
    colors: [Color(0xFF89216B), Color(0xFFDA4453)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
