import 'package:flutter/material.dart';

class CommonProvider extends ChangeNotifier {
  final bool isTablet =
      MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.shortestSide > 600;
}
