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
  Brightness get brightness => _brightness;
  ColorScheme get scheme => _scheme;

  // Method to update dynamic colors
  void updateLocalAccentColour(Color newColor) {
    _scheme = ColorScheme.fromSeed(seedColor: _accentColour, brightness: _brightness);
    _accentColour = newColor;
    notifyListeners();
  }

  void updateLocalBrightness(Brightness newBrightness) {
    _scheme = ColorScheme.fromSeed(seedColor: _accentColour, brightness: _brightness);
    _brightness = newBrightness;
    notifyListeners();
  }

  void updateLocalColorScheme(Color newAccentColour, Brightness newBrightness) {
    _scheme = ColorScheme.fromSeed(seedColor: newAccentColour, brightness: newBrightness);
    _accentColour = newAccentColour;
    _brightness = newBrightness;
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
  static const Color NUS = Color(0xFF003D7C);

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
      case BusOperator.NUS:
        return (AppColors.NUS, Colors.white); // Accessing static getter
      default:
        // Accessing instance's scheme
        return (_scheme.primary, _scheme.onPrimary);
    }
  }

  (Color, Color) getNUSServiceColor(String serviceNo) {
    switch (serviceNo.toUpperCase()) {
      case 'A1':
        return (const Color(0xFFFB0101), Colors.white);
      case 'A2':
        return (const Color(0xFFE3CF0E), Colors.black);
      case 'D1':
        return (const Color(0xFFC77DE0), Colors.white);
      case 'D2':
        return (const Color(0xFF6E1D72), Colors.white);
      case 'K':
        return (const Color(0xFF33599C), Colors.white);
      case 'E':
        return (const Color(0xFF02B050), Colors.white);
      case 'BTC':
        return (const Color(0xFFEF8135), Colors.white);
      case 'L':
        return (const Color(0xFFBFBFBF), Colors.black);
      case 'R1':
        return (const Color(0xFFEE8136), Colors.white);
      case 'R2':
        return (const Color(0xFF008000), Colors.white);
      case 'P':
        return (const Color(0xFFBEBEBE), Colors.black);
      default:
        return (_scheme.primary, _scheme.onPrimary);
    }
  }
}
