import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle loraHeadingStyle({
  double fontSize = 20,
  FontWeight fontWeight = FontWeight.bold,
  Color? color,
}) {
  return GoogleFonts.lora(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}
