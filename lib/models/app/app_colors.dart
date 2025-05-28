// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';

class AppColors with ChangeNotifier {
  // Instance variables for dynamic colors
  Color _accentColour = const Color(0xFF7E6BFF);
  Brightness _brightness = Brightness.dark;
  late ColorScheme _scheme = ColorScheme.fromSeed(
    seedColor: _accentColour,
    brightness: _brightness,
  );

  // Public getters for instance variables
  Color get accentColour => _accentColour;
  ColorScheme get scheme => _scheme;

  // Method to update dynamic colors
  void updateLocalAccentColour(Color newColor) {
    _accentColour = newColor;
    _scheme = ColorScheme.fromSeed(
      seedColor: _accentColour,
      brightness: _brightness,
    );
    notifyListeners();
  }

  void updateLocalBrightness(Brightness newBrightness) {
    _brightness = newBrightness;
    _scheme = ColorScheme.fromSeed(
      seedColor: _accentColour,
      brightness: _brightness,
    );
    notifyListeners();
  }

  void updateLocalColorScheme(ColorScheme newScheme) {
    _scheme = newScheme;
    _brightness = newScheme.brightness;
    notifyListeners();
  }

  // Static getters for constant colors
  static Color get veryPurple => const Color(0xFF7E6BFF);

  Color get prettyGreen => _brightness == Brightness.dark ? Color(0xFF96E2B6) : Color(0xFF52AD7D);
  Color get notReallyYellow =>
      _brightness == Brightness.dark ? Color(0xFFFFCEA6) : Color(0xFFF5A650);
  Color get sortaRed => _brightness == Brightness.dark ? Color(0xFFFFAA8F) : Color(0xFFF07251);

  static const Color SBST = Color(0xFF9C40A6);
  static const Color SMRT = Color(0xFFE23C46);
  static const Color TTS = Color(0xFF47A854);
  static const Color GAS = Color(0xFFF6C322);

  // Instance method for operator colors, as it depends on the instance's scheme for the default case
  (Color, Color) getOperatorColor(BusOperator operator) {
    switch (operator) {
      case BusOperator.SBST:
        return (AppColors.SBST, Colors.white); // Accessing static getter
      case BusOperator.SMRT:
        return (AppColors.SMRT, Colors.white); // Accessing static getter
      case BusOperator.TTS:
        return (AppColors.TTS, Colors.black); // Accessing static getter
      case BusOperator.GAS:
        return (AppColors.GAS, Colors.black); // Accessing static getter
      default:
        // Accessing instance's scheme
        return (_scheme.primary, _scheme.onPrimary);
    }
  }
}
