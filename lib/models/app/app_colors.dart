// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';

class AppColors with ChangeNotifier {
  static Color accentColour = const Color(0xFF7E6BFF);
  static ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: accentColour,
    brightness: Brightness.dark,
  );

  void updateLocalAccentColour(Color newColor) {
    accentColour = newColor;
    scheme = ColorScheme.fromSeed(
      seedColor: accentColour,
      brightness: Brightness.dark,
    );
    notifyListeners();
  }

  static const Color veryPurple = Color(0xFF7E6BFF);
  static Color kindaGrey = scheme.onSurface.withAlpha(220);

  static const Color prettyGreen = Color(0xFF96E2B6);
  static const Color notReallyYellow = Color(0xFFFFCEA6);
  static const Color sortaRed = Color(0xFFFFAA8F);

  static const Color SBST = Color(0xFF9C40A6);
  static const Color SMRT = Color(0xFFE23C46);
  static const Color TTS = Color(0xFF47A854);
  static const Color GAS = Color(0xFFF6C322);

  // function that returns the correct colours for each bus operator
  static (Color, Color) getOperatorColor(BusOperator operator) {
    switch (operator) {
      case BusOperator.SBST:
        return (AppColors.SBST, Colors.white);
      case BusOperator.SMRT:
        return (AppColors.SMRT, Colors.white);
      case BusOperator.TTS:
        return (AppColors.TTS, Colors.black);
      case BusOperator.GAS:
        return (AppColors.GAS, Colors.black);
      default:
        return (AppColors.scheme.primary, AppColors.scheme.onPrimary);
    }
  }
}
