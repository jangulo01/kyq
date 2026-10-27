import 'package:flutter/material.dart';

/// Color de marca de Kyq.
const kyqSeedColor = Color(0xFF6A1B9A);

/// Tema común de las apps Kyq.
ThemeData kyqTheme({Brightness brightness = Brightness.light}) => ThemeData(
  colorSchemeSeed: kyqSeedColor,
  brightness: brightness,
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
);
