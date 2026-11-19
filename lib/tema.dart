import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const verde = Color(0xFF0B5147);
  static const verdeHondo = Color(0xFF06322C);
  static const ocre = Color(0xFFE08A1F);
  static const exito = Color(0xFF1E8A5F);
  static const advertencia = Color(0xFFB8791A);
  static const error = Color(0xFFC0392E);
  static const info = Color(0xFF2E6BAF);
  static const fondo = Color(0xFFEDF1EF);
  static const borde = Color(0xFFDCE3E0);
  static const tenue = Color(0xFF75857F);
  static const medio = Color(0xFF41524D);
  static const texto = Color(0xFF0E1A17);
}

TextStyle archivo(double tam, {FontWeight w = FontWeight.w700, Color c = C.texto, double? espacio}) {
  return GoogleFonts.archivo(fontSize: tam, fontWeight: w, color: c, letterSpacing: espacio);
}

TextStyle plex(double tam, {FontWeight w = FontWeight.w400, Color c = C.texto}) {
  return GoogleFonts.ibmPlexSans(fontSize: tam, fontWeight: w, color: c);
}

ThemeData temaApp() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.verde, primary: C.verde),
    scaffoldBackgroundColor: C.fondo,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(),
  );
}
