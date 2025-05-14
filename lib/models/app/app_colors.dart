// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:transito/models/enums/bus_operator_enum.dart';

class AppColors with ChangeNotifier {
  Color primaryColor = const Color(0xFF7E6BFF);

  static Color accentColour = const Color(0xFF7E6BFF);

  static const Color veryPurple = Color(0xFF7E6BFF);
  static const Color kindaGrey = Color(0xFFD8DBE2);

  static const Color prettyGreen = Color(0xFF5BDB7A);
  static const Color notReallyYellow = Color(0xFFF7A74D);
  static const Color sortaRed = Color(0xFFF46A49);

  static const Color SBST = Color(0xFF8A2890);
  static const Color SMRT = Color(0xFFDC1C27);
  static const Color TTS = Color(0xFF389643);
  static const Color GAS = Color(0xFFF4BD00);

  static Color cardBg(BuildContext context) => Theme.of(context).colorScheme.surfaceContainer;
  static Color drawerBg(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLow;
  static const Color inputFieldBg = Color(0xff202020);

  // function that returns the correct colours for each bus operator
  static Color getOperatorColor(BusOperator operator) {
    switch (operator) {
      case BusOperator.SBST:
        return AppColors.SBST;
      case BusOperator.SMRT:
        return AppColors.SMRT;
      case BusOperator.TTS:
        return AppColors.TTS;
      case BusOperator.GAS:
        return AppColors.GAS;
      default:
        return AppColors.accentColour;
    }
  }
}
